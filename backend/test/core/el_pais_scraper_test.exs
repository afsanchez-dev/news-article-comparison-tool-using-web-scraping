defmodule NewspaperScraper.Core.ElPaisScraperTest do
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Core.ElPaisScraper
  alias NewspaperScraper.Model.Author
  alias NewspaperScraper.Utils.Test.TestUtils
  use ExUnit.Case, async: true

  @reponses_path Application.compile_env(:newspaper_scraper, :el_pais_search_responses_path)
  @base_url Application.compile_env(:newspaper_scraper, :el_pais_base_url)

  setup_all do
    parsed_json = TestUtils.read_and_parse_JSON!(@reponses_path)
    [responses: parsed_json]
  end

  # ===================================================================================

  describe "get_scraper_name/0" do
    test "get_scraper_name works as expected" do
      assert "el-pais" === ElPaisScraper.get_scraper_name()
    end
  end

  # ===================================================================================

  describe "scraper_check/1" do
    test "url belongs to scraper" do
      url =
        "https://cincodias.elpais.com/cincodias/2023/09/08/legal/1694176476_943900.html?rel=buscador_noticias"

      assert :ok === ElPaisScraper.scraper_check(url)
    end

    # ---------------------------------------------------------------------------------

    test "url doesn't belong to scraper" do
      url = "https://www.elmundo.es/internacional"
      assert {:error, "invalid url"} === ElPaisScraper.scraper_check(url)
    end
  end

  # ===================================================================================

  describe "get_selectors/1" do
    test "returns selectors properly when function exists" do
      funcs = [
        :check_premium,
        :parse_art_header,
        :parse_art_authors,
        :parse_art_date,
        :parse_art_body
      ]

      Enum.each(
        funcs,
        fn func ->
          selectors = ElPaisScraper.get_selectors(func)
          assert length(selectors) !== 0
        end
      )
    end

    # ---------------------------------------------------------------------------------

    test "returns nil when function doesn't exist" do
      func = :non_existing

      assert ElPaisScraper.get_selectors(func) === nil
    end
  end

  # ===================================================================================

  describe "ElPaisScraper.search_articles/3" do
    test "search is not empty" do
      search_res = ElPaisScraper.search_articles("nuevas tecnologías", 1, 3)

      assert {:ok, res} = search_res
      assert length(res) !== 0
    end

    # ---------------------------------------------------------------------------------

    test "search results have expected format" do
      search_res = ElPaisScraper.search_articles("nuevas tecnologías", 1, 3)

      exptd_keys = [
        "authors",
        "title",
        "excerpt",
        "url",
        "updatedTs"
      ]

      assert {:ok, res} = search_res

      # First we get the keys of the results
      Enum.each(
        res,
        fn article ->
          keys = Map.keys(article)
          # Then we check if the ones we expect are present in our results
          Enum.each(
            exptd_keys,
            fn expected_key ->
              assert Enum.member?(keys, expected_key)
            end
          )
        end
      )
    end

    # ---------------------------------------------------------------------------------

    test "should fail when ElPaisAPI fails" do
      assert {:error, "not found"} = ElPaisScraper.search_articles("API_not_found", 1, 3)

      assert {:error, "internal server error"} =
               ElPaisScraper.search_articles("API_server_error", 1, 3)
    end
  end

  # =================================================================================

  describe "ElPaisScraper.parse_search_results/1" do
    test "parsing works as expected", context do
      responses = context[:responses]
      to_parse = responses["search_articles"]["valid_resp"]["articles"]

      exptd_art_summ = %ArticleSummary{
        newspaper: "El País",
        authors: [
          %Author{
            name: "Alfonso De Frutos Sastre",
            url: "https://elpais.com/autor/alfonso-de-frutos-sastre/"
          }
        ],
        title: "Apple lanzará unos AirPods Max con puerto USB Tipo C, pero tardará en llegar",
        excerpt: "Un cambio muy lógico",
        date_time:
          1_698_670_712
          |> DateTime.from_unix()
          |> Tuple.to_list()
          |> Enum.at(1)
          |> DateTime.to_iso8601(:extended),
        url:
          "http://localhost:8081/get_article?url=https://cincodias.elpais.com/cincodias/2023/10/30/gadgets/1698670440_830646.html",
        is_premium: false
      }

      assert {:ok, art_summs} = ElPaisScraper.parse_search_results(to_parse)

      assert exptd_art_summ === Enum.at(art_summs, 0)
    end

    # ---------------------------------------------------------------------------------

    test "parsing should fail if no articles were found", context do
      responses = context[:responses]
      nil_resp = responses["search_articles"]["invalid_resps"]["empty_resp"]["articles"]

      assert {:error, "no articles found to parse"} = ElPaisScraper.parse_search_results(nil_resp)
    end

    # ---------------------------------------------------------------------------------

    test "parsing date should fail when unix time is invalid", context do
      responses = context[:responses]
      bad_date_time = responses["search_articles"]["invalid_resps"]["bad_datetime"]["articles"]

      assert {:ok, [art]} = ElPaisScraper.parse_search_results(bad_date_time)
      assert {:error, :invalid_unix_time} = art.date_time
    end
  end

  # =================================================================================

  describe "get_article/1" do
    test "get_article works as expected" do
      url =
        @base_url <>
          "/get_article?url=https://cincodias.elpais.com/cincodias/2023/10/30/gadgets/1698670440_830646.html"

      assert {:ok, {_html, _url}} = ElPaisScraper.get_article(url)
    end

    # ---------------------------------------------------------------------------------

    test "get_article should fail when url doesn't exist" do
      url = "https://www.elpaisthistestshouldfail.udc"

      assert {:error, :econnrefused} = ElPaisScraper.get_article(url)
    end
  end

  # =================================================================================

  describe "parse_article/2" do
    test "parse_article works as expected" do
      url =
        @base_url <>
          "/get_article?url=https://cincodias.elpais.com/cincodias/2023/10/30/gadgets/1698670440_830646.html"

      {:ok, res} = Tesla.get(url)
      html_doc = res.body

      exptd_newspaper = "El País"

      exptd_headline =
        "Apple lanzará unos AirPods Max con puerto USB Tipo C, pero tardará en llegar"

      exptd_subheadline = "Un cambio muy lógico"

      exptd_authors = [
        %Author{
          name: "Alfonso de Frutos Sastre",
          url: "https://http://localhost:8081/autor/alfonso_de_frutos_sastre/a/"
        }
      ]

      exptd_last_date_time = "2023-10-30T13:58:17+01:00"

      exptd_body_first_p = %{
        p:
          String.replace(
            """
            Apple ha tenido que adoptar el puerto USB Tipo C por la fuerza. La nueva
            normativa de la UE es muy clara, por lo que la firma con sede en Cupertino
            lanzó los iPhone 15, iPhone 15 Plus, iPhone 15 Pro y iPhone 15 Pro Max.
            Además, mostraron unos AirPods que también cuentan con puerto USB Tipo C.
            """,
            "\n",
            " "
          )
          |> String.trim()
      }

      exptd_body_last_p = %{
        p:
          String.replace(
            """
            Por no hablar de su diseño premium, ya que los AirPods Max están fabricados
            con materiales de alta calidad, como aluminio anodizado, acero inoxidable y
            piel sintética. Pero el próximo modelo no tendrá más mejoras más allá del
            nuevo conector. ¿Suficiente para revitalizar las ventas? Lo dudamos mucho.
            """,
            "\n",
            " "
          )
          |> String.trim()
      }

      exptd_url = url

      assert {:ok, parsed_art} = ElPaisScraper.parse_article(html_doc, url)

      assert exptd_newspaper === parsed_art.newspaper
      assert exptd_headline === parsed_art.headline
      assert exptd_subheadline === parsed_art.subheadline
      assert exptd_authors === parsed_art.authors
      assert exptd_last_date_time === parsed_art.last_date_time
      assert exptd_body_first_p === parsed_art.body |> Enum.at(0)
      assert exptd_body_last_p === parsed_art.body |> Enum.at(-1)
      assert exptd_url === parsed_art.url
    end

    # ---------------------------------------------------------------------------------

    test "parses articles properly when authors don't have url" do
      url =
        @base_url <>
          "/get_article?url=https://elpais.com/america-futura/2023-10-25/enfrentar-la-crisis-climatica-en-el-campo.html"

      {:ok, res} = Tesla.get(url)
      html_doc = res.body

      exptd_authors = [
        %Author{
          name: "Oliver Page",
          url: nil
        }
      ]

      assert {:ok, parsed_art} = ElPaisScraper.parse_article(html_doc, url)
      assert exptd_authors === parsed_art.authors
    end

    # ---------------------------------------------------------------------------------

    test "should fail when the article is premium" do
      url =
        @base_url <>
          "/get_article?url=https://elpais.com/clima-y-medio-ambiente/2023-10-18/la-insuficiente-respuesta-de-la-justicia-espanola-al-actual-cambio-climatico.html"

      {:ok, res} = Tesla.get(url)
      html_doc = res.body

      assert {:error, "forbidden content"} = ElPaisScraper.parse_article(html_doc, url)
    end

    # ---------------------------------------------------------------------------------

    test "should fail parsing empty HTML" do
      html = ""
      url = "http://testurl.udc"

      assert {:error, [_h | _t]} = ElPaisScraper.parse_article(html, url)
    end

    # ---------------------------------------------------------------------------------

    test "should fail parsing HTML without requested info" do
      html = """
      <!DOCTYPE html>
      <html lang='es'>
      </html>
      """

      url = "http://testurl.udc"
      assert {:error, [_h | _t]} = ElPaisScraper.parse_article(html, url)
    end
  end
end
