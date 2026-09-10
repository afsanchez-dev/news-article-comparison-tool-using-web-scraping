defmodule NewspaperScraper.Mocks.ElMundoMockServer do
  @moduledoc """
  This module mocks https://www.elmundo.es/ behaviour
  """
  # alias NewspaperScraper.Core.ElMundoScraper
  # alias NewspaperScraper.Utils.Test.TestUtils
  # alias NewspaperScraper.Utils.Core.ParsingUtils
  require Logger
  use Plug.Router

  @server_url Application.compile_env(:newspaper_scraper, :el_mundo_base_url)
  @responses_path Application.compile_env(:newspaper_scraper, :el_mundo_search_responses_path) ||
                    "/non_existing_path"
  @articles_path Application.compile_env(:newspaper_scraper, :el_mundo_articles_path) ||
                   "/non_existing_path"

  plug(Plug.Logger)

  plug(:match)

  plug(:dispatch)

  # ===================================================================================

  def init(_opts) do
    Logger.info("ElMundoMockServer running on: #{@server_url}")
  end

  # -----------------------------------------------------------------------------------

  get "/search_articles" do
    query_params =
      fetch_query_params(conn).query_params

    topic = query_params["q"]

    case topic do
      "API_not_found" ->
        send_resp(conn, 404, "not found")

      "API_server_error" ->
        send_resp(conn, 500, "internal server error")

      "incomplete_resp" ->
        conn = put_resp_content_type(conn, "text/html")
        send_file(conn, 200, @responses_path <> "/incomplete.html")

      _ ->
        conn = put_resp_content_type(conn, "text/html")
        send_file(conn, 200, @responses_path <> "/nuevas_tecnologias.html")
    end
  end

  get "/get_article" do
    query_params =
      fetch_query_params(conn).query_params

    url = query_params["url"]

    case url do
      "normal_art" ->
        conn = put_resp_content_type(conn, "text/html")
        send_file(conn, 200, @articles_path <> "/normal_art.html")

      "interview_art" ->
        conn = put_resp_content_type(conn, "text/html")
        send_file(conn, 200, @articles_path <> "/interview_art.html")
    end
  end
end
