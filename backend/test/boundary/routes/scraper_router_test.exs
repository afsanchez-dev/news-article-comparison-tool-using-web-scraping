defmodule Boundary.Routes.ScraperRouterTest do
  alias NewspaperScraper.Boundary.Routes.ScraperRouter
  alias NewspaperScraper.Boundary.ScraperManager
  use ExUnit.Case, async: true
  use Plug.Test

  @opts ScraperRouter.init([])
  @base_url Application.compile_env(:newspaper_scraper, :el_pais_base_url)

  setup_all do
    start_supervised!({ScraperManager, [name: ScraperManager, args: [num_req_handlers: 4]]})
    :ok
  end

  # ===================================================================================

  describe "get /search_articles" do
    test "works as expected" do
      topic = "test_topic"
      page = 0
      limit = 2

      build_conn = conn(:get, "/search_articles?topic=#{topic}&page=#{page}&limit=#{limit}")
      conn = ScraperRouter.call(build_conn, @opts)

      assert {:ok, _} = Jason.decode(conn.resp_body)
    end

    # -----------------------------------------------------------------------------------

    test "returns data errors properly" do
      topic = "empty_resp"
      page = 0
      limit = 2

      build_conn = conn(:get, "/search_articles?topic=#{topic}&page=#{page}&limit=#{limit}")
      conn = ScraperRouter.call(build_conn, @opts)

      assert {:ok, parsed_err} = Jason.decode(conn.resp_body)
      assert is_list(parsed_err)
      first_elem = Enum.at(parsed_err, 0)

      first_elem_err = %{
        "results" => %{"error" => "no articles found to parse"},
        "scraper" => "el-pais"
      }

      assert first_elem_err === first_elem
    end

    # -----------------------------------------------------------------------------------

    test "returns validation errors properly" do
      topic = "empty_resp"
      page = "abc34"
      limit = 11

      build_conn = conn(:get, "/search_articles?topic=#{topic}&page=#{page}&limit=#{limit}")
      conn = ScraperRouter.call(build_conn, @opts)

      exptd_err = %{
        "error" => [
          %{"page" => "must be an integer"},
          %{"limit" => "max. limit exceeded"}
        ]
      }

      assert {:ok, parsed_err} = Jason.decode(conn.resp_body)
      assert exptd_err === parsed_err
    end
  end

  # ===================================================================================

  describe "/get_article" do
    test "works as expected" do
      url =
        @base_url <>
          "/get_article?url=" <>
          "https://cincodias.elpais.com/cincodias/2023/10/30/gadgets/1698670440_830646.html"

      build_conn = conn(:get, "/get_article?url=#{url}")
      conn = ScraperRouter.call(build_conn, @opts)

      assert {:ok, _} = Floki.parse_document(conn.resp_body)
    end
  end

  # -----------------------------------------------------------------------------------

  test "returns errors properly" do
    url = "test_url"

    build_conn = conn(:get, "/get_article?url=#{url}")
    conn = ScraperRouter.call(build_conn, @opts)

    exptd_error = %{
      "error" => [
        %{"url" => "must be a valid newspaper"}
      ]
    }

    assert {:ok, parsed_err} = Jason.decode(conn.resp_body)
    assert exptd_error === parsed_err
  end

  # ===================================================================================

  describe "unknown route" do
    test "returns not found" do
      build_conn = conn(:get, "/non_existing_route")
      conn = ScraperRouter.call(build_conn, @opts)

      exptd_error = "not found"
      assert exptd_error === conn.resp_body
    end
  end
end
