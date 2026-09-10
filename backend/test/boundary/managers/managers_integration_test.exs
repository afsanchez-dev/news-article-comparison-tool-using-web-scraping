defmodule Boundary.Managers.ManagersIntegrationTest do
  alias NewspaperScraper.Model.AppError
  alias NewspaperScraper.Boundary.ScraperManager

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  @base_url Application.compile_env(:newspaper_scraper, :el_pais_base_url)
  @num_req_handlers 1

  defp supervise_normal_children do
    start_supervised(
      {ScraperManager, [name: ScraperManager, args: [num_req_handlers: @num_req_handlers]]}
    )
  end

  defp supervise_failed_children do
    start_supervised({ScraperManager, [name: ScraperManager, args: []]})
  end

  defp clean_manager_supervision_tree do
    man_sup = GenServer.call(ScraperManager, :get_state)
    Supervisor.stop(man_sup)
  end

  # ===================================================================================

  describe "start_link/1" do
    test "supervises expected children" do
      assert {:ok, _pid} = supervise_normal_children()

      sup_pid = GenServer.call(ScraperManager, :get_state)

      children_map = Supervisor.count_children(sup_pid)

      assert children_map.active === @num_req_handlers + 2

      assert :ok === clean_manager_supervision_tree()
    end

    # ---------------------------------------------------------------------------------

    test "should not start if errors happen" do
      assert {:error, _e} = supervise_failed_children()
    end
  end

  # ===================================================================================

  describe "search_articles/3" do
    test "works as expected" do
      assert {:ok, _pid} = supervise_normal_children()

      res = ScraperManager.search_articles("test_topic", 1, 2)

      assert is_list(res)
      assert :ok === clean_manager_supervision_tree()
    end

    # ---------------------------------------------------------------------------------

    test "returns error when request stage fails" do
      assert {:ok, _pid} = supervise_normal_children()

      res = ScraperManager.search_articles("API_not_found", 1, 2)

      assert is_list(res)
      first_elem = Enum.at(res, 0)

      first_elem_err = %{
        scraper: "el-pais",
        results: %NewspaperScraper.Model.AppError{error: "not found"}
      }

      assert first_elem_err === first_elem
      assert :ok === clean_manager_supervision_tree()
    end

    # ---------------------------------------------------------------------------------

    test "returns error when parsing stage fails" do
      assert {:ok, _pid} = supervise_normal_children()

      res = ScraperManager.search_articles("empty_resp", 1, 2)

      assert is_list(res)
      first_elem = Enum.at(res, 0)

      first_elem_err = %{
        scraper: "el-pais",
        results: %AppError{error: "no articles found to parse"}
      }

      assert first_elem_err === first_elem
      assert :ok === clean_manager_supervision_tree()
    end
  end

  # ===================================================================================

  describe "get_articles/1" do
    test "works as expected" do
      assert {:ok, _pid} = supervise_normal_children()

      url =
        @base_url <>
          "/get_article?url=https://cincodias.elpais.com/cincodias/2023/10/30/gadgets/1698670440_830646.html"

      assert {:ok, _res} = ScraperManager.get_article(url)
      assert :ok === clean_manager_supervision_tree()
    end

    # ---------------------------------------------------------------------------------

    test "returns error when request stage fails" do
      assert {:ok, _pid} = supervise_normal_children()

      url = "test_url"

      assert {:error, "invalid url"} = ScraperManager.get_article(url)
      assert :ok === clean_manager_supervision_tree()
    end
  end

  # ---------------------------------------------------------------------------------

  test "returns error when parsing stage fails" do
    assert {:ok, _pid} = supervise_normal_children()

    url =
      @base_url <>
        "/get_article?url=elpais.com/failed_html"

    assert {:error, _res} = ScraperManager.get_article(url)
    assert :ok === clean_manager_supervision_tree()
  end

  # ===================================================================================
  describe "terminate/2" do
    test "works as expected" do
      assert {:ok, _pid} = supervise_normal_children()

      assert capture_log(fn -> GenServer.stop(ScraperManager) end) =~ "ScraperManager terminated"
      assert :ok === clean_manager_supervision_tree()
    end
  end
end
