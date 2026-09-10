defmodule NewspaperScraper.Mocks.ElPaisMockServer do
  @moduledoc """
  This module mocks https://elpais.com behaviour
  """
  alias NewspaperScraper.Core.ElPaisScraper
  alias NewspaperScraper.Utils.Test.TestUtils
  alias NewspaperScraper.Utils.Core.ParsingUtils
  require Logger
  use Plug.Router
  use Agent

  @server_url Application.compile_env(:newspaper_scraper, :el_pais_base_url)
  @responses_path Application.compile_env(:newspaper_scraper, :el_pais_search_responses_path) ||
                    "/non_existing_path"
  @resources_path Application.compile_env(:newspaper_scraper, :el_pais_resources_path)
  @agent_name :el_pais_agent

  plug(Plug.Logger)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # ===================================================================================

  def init(_opts) do
    Logger.info("ElPaisMockServer running on: #{@server_url}")

    try do
      resources = TestUtils.read_and_parse_JSON!(@responses_path, keys: :atoms)
      Agent.start_link(fn -> resources end, name: @agent_name)
    rescue
      _e -> Logger.critical("Unable to start el_pais_mock_server")
    end
  end

  # -----------------------------------------------------------------------------------

  get "/search_articles" do
    query_params =
      fetch_query_params(conn).query_params

    {:ok, transformed_query} = Jason.decode(query_params["query"])

    topic = transformed_query["q"]

    resources = Agent.get(@agent_name, & &1)

    case topic do
      "API_not_found" -> send_resp(conn, 404, "not found")
      "API_server_error" -> send_resp(conn, 500, "internal server error")
      "empty_resp" -> handle_resp(:json, conn, resources.search_articles.invalid_resps.empty_resp)
      _ -> handle_resp(:json, conn, resources.search_articles.valid_resp)
    end
  end

  # -----------------------------------------------------------------------------------

  get "/get_article" do
    query_params =
      fetch_query_params(conn).query_params

    url = query_params["url"]

    case url do
      "elpais.com/failed_html" ->
        handle_resp(:json, conn, "failed")

      _ ->
        file_name = String.split(url, "/") |> Enum.at(-1)
        path = Enum.join([@resources_path, "/", file_name], "")

        case File.exists?(path) do
          true ->
            handle_resp(:html, conn, path)

          false ->
            html = get_and_convert_article(url)
            File.touch!(path)
            File.write!(path, html)
            handle_resp(:html, conn, path)
        end
    end
  end

  # -----------------------------------------------------------------------------------

  defp handle_resp(:json, conn, data) do
    {:ok, res} = Jason.encode(data)

    conn = put_resp_content_type(conn, "application/json")
    send_resp(conn, 200, res)
  end

  defp handle_resp(:html, conn, path) do
    conn = put_resp_content_type(conn, "text/html")
    send_file(conn, 200, path)
  end

  # -----------------------------------------------------------------------------------

  defp get_and_convert_article(url) do
    html =
      with {:ok, res} <- Tesla.get(url),
           {:ok, html} <- Floki.parse_document(res.body),
           do: html,
           else: (error -> error)

    to_convert_html =
      case ParsingUtils.check_premium(html, ElPaisScraper) do
        true -> filter_out_premium_content(html)
        false -> html
      end

    Floki.raw_html(to_convert_html)
  end

  # -----------------------------------------------------------------------------------

  defp filter_out_premium_content(html) do
    ids = ElPaisScraper.get_selectors({:check_premium, 0})

    Floki.traverse_and_update(html, fn
      {"div", attrs, children} ->
        transformed_attrs = ParsingUtils.transform_attributes(attrs)
        exists = Enum.member?(ids, transformed_attrs["id"])

        if exists do
          {"div", attrs, []}
        else
          {"div", attrs, children}
        end

      other ->
        other
    end)
  end
end
