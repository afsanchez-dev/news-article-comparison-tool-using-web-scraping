defmodule Core.ElMundoScraperTest do
  alias NewspaperScraper.Model.Author
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Core.ElMundoScraper
  use ExUnit.Case, async: true

  @search_url Application.compile_env(:newspaper_scraper, :el_mundo_api_url)

  # ===================================================================================

  describe "get names" do
    test "get_scraper_name/0 works as expected" do
      assert "el-mundo" === ElMundoScraper.get_scraper_name()
    end

    test "get_newspaper_name/0 works as expected" do
      assert "El Mundo" === ElMundoScraper.get_newspaper_name()
    end
  end

  # -----------------------------------------------------------------------------------

  describe "scraper_check/1" do
    test "works for El Mundo URLs" do
      urls = [
        "https://elmundo.es",
        "https://www.elmundo.es/economia.html",
        "https://www.elmundo.es/espana/2023/12/26/658b1445fc6c83a5568b45a7.html",
        "https://ariadna.elmundo.es/buscador/archivo.html?q=test-topic&fd=0&td=0&n=10&w=80&s=0&fecha_busq_avanzada=1"
      ]

      Enum.each(urls, fn url ->
        assert :ok === ElMundoScraper.scraper_check(url)
      end)
    end

    test "returns an error if urls do not match" do
      urls = [
        "https://testurl.es",
        "https://www.elpais.es/economia.html",
        "https://www.abc.es/espana/2023/12/26/658b1445fc6c83a5568b45a7.html",
        "https://this.test.es/buscador/archivo.html"
      ]

      Enum.each(urls, fn url ->
        assert {:error, "invalid url"} === ElMundoScraper.scraper_check(url)
      end)
    end
  end

  # -----------------------------------------------------------------------------------

  describe "get_selectors/1" do
    test "finds all selectors" do
      functions = [
        parse_search_results: [".lista_resultados"],
        check_premium: [".ue-c-article__premium-tag"],
        parse_art_header: [".ue-c-article"],
        parse_art_authors: [".ue-c-article__author-name", ".ue-c-article__byline-name"],
        parse_art_date: [".ue-c-article__publishdate"],
        parse_art_body: [".ue-l-article__body"]
      ]

      Enum.map(functions, fn {fun, selectors} ->
        assert selectors === ElMundoScraper.get_selectors(fun)
      end)
    end

    test "returns nil when function not defined" do
      assert nil === ElMundoScraper.get_selectors(:non_existing_fun)
    end
  end

  # -----------------------------------------------------------------------------------

  describe "search_articles/3" do
    test "returns error when resource not found" do
      assert {:error, _e} = ElMundoScraper.search_articles("API_not_found", 0, 4)
    end

    test "returns error when server is not avaliable" do
      assert {:error, _e} = ElMundoScraper.search_articles("API_server_error", 1, 4)
    end

    test "returns ok when request is successful" do
      assert {:ok, _resp} = ElMundoScraper.search_articles("testTopic", 2, 5)
    end
  end

  # -----------------------------------------------------------------------------------

  describe "parse_search_results/1" do
    test "returns error when is not possible to parse" do
      {:ok, res} = Tesla.get(@search_url <> "?q=incomplete_resp")
      html_doc = res.body

      {:error, _e} = ElMundoScraper.parse_search_results(html_doc)
    end

    test "parses results as expected" do
      {:ok, res} = Tesla.get(@search_url <> "?q=testTopic")
      html_doc = res.body

      {:ok, res} =
        ElMundoScraper.parse_search_results(html_doc)

      newspaper = "El Mundo"

      exptd_art_summ1 = %ArticleSummary{
        newspaper: newspaper,
        authors: [
          %Author{
            name: "Michela Roveli",
            url: nil
          }
        ],
        title:
          "IA generativa, computación cuántica, realidad mixta y otras tendencias tecnológicas que llegarán en 2024",
        excerpt:
          "El desarrollo de la Inteligencia artificial, la nueva carrera espacial o la búsqueda de energías más sostenibles marcarán los avances tecnológicos de 2024",
        date_time: "2023-12-31T10:14:45Z",
        url:
          "https://www.elmundo.es/tecnologia/creadores/2023/12/31/65913999e85ecef7108b45c8.html",
        is_premium: false
      }

      art_summ0 = Enum.at(res, 0)
      art_summ3 = Enum.at(res, 3)

      assert exptd_art_summ1 === art_summ0
      assert nil === art_summ3.authors
    end
  end

  # -----------------------------------------------------------------------------------

  describe "parse_article" do
    test "works as expected" do
      {:ok, normal_art_doc} = File.read("./priv/test/el_mundo/articles/normal_art.html")
      {:ok, interview_art_doc} = File.read("./priv/test/el_mundo/articles/interview_art.html")

      {:ok, _res} = ElMundoScraper.parse_article(normal_art_doc, "test_url1")
      {:ok, _res} = ElMundoScraper.parse_article(interview_art_doc, "test_url2")
    end
  end
end
