defmodule NewspaperScraper.Boundary.Routes.ScraperRouter do
  @moduledoc """
  This module implements the routing for scraping functionalities
  """
  require Logger
  alias NewspaperScraper.Utils.Routes.RouterUtils
  alias NewspaperScraper.Boundary.ScraperAPI

  use Plug.Router

  plug(Plug.Logger)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(CORSPlug, origin: ["*"])

  plug(:dispatch)

  # ===================================================================================

  # Transforms search_articles query parameters into their correct types
  @spec transform_search_articles_query_params(map()) :: map()
  defp transform_search_articles_query_params(query) do
    for {key, value} <- query, into: %{} do
      if key === :page or key === :limit do
        case Integer.parse(value) do
          {num, _rem} -> {key, num}
          _ -> {key, value}
        end
      else
        {key, value}
      end
    end
  end

  # ---------------------------------------------------------------------------------

  # Handles error enconding and reply
  @spec handle_error(Plug.Conn.t(), {:error, any()}) :: Plug.Conn.t() | no_return()
  defp handle_error(conn, error) do
    {:ok, error_res} = RouterUtils.transform_error(error) |> Jason.encode()
    send_resp(conn, 400, error_res)
  end

  # ===================================================================================
  # Scraper routes
  # ===================================================================================

  get "/search_articles" do
    query_params =
      fetch_query_params(conn).query_params
      |> RouterUtils.transform_query_params()
      |> transform_search_articles_query_params()

    Logger.log(:info, query_params)

    with parsed_art_summs when is_list(parsed_art_summs) <-
           ScraperAPI.search_articles(query_params),
         transformed <- Enum.map(parsed_art_summs, &RouterUtils.transform_error/1),
         {:ok, res} <- Jason.encode(transformed) do
      send_resp(conn, 200, res)
    else
      error ->
        handle_error(conn, error)
    end
  end

  # ---------------------------------------------------------------------------------

  get "/get_article" do
    query_params =
      fetch_query_params(conn).query_params
      |> RouterUtils.transform_query_params()

    Logger.log(:info, query_params)

    with {:ok, parsed_art} <- ScraperAPI.get_article(query_params),
         {:ok, res} <- Jason.encode(parsed_art) do
      send_resp(conn, 200, res)
    else
      error ->
        handle_error(conn, error)
    end
  end

  # ---------------------------------------------------------------------------------

  match(_, do: send_resp(conn, 404, "not found"))
end
