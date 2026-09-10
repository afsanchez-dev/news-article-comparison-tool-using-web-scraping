defmodule NewspaperScraper.Core.LaVozDeGaliciaScraper do
  @moduledoc """
  This module contains all the logic needed for scraping https://www.lavozdegalicia.es/
  """
  alias NewspaperScraper.Core.LaVozDeGaliciaScraper
  alias NewspaperScraper.Core.ScraperParser
  alias NewspaperScraper.Core.Scraper
  alias NewspaperScraper.Utils.Core.ParsingUtils
  alias NewspaperScraper.Core.ScraperCommImpl
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Model.Author

  @behaviour Scraper
  @behaviour ScraperParser

  @scraper_name "la-voz-de-galicia"
  @newspaper_name "La Voz De Galicia"
  @base_url Application.compile_env(:newspaper_scraper, :la_voz_de_galicia_base_url)
  @api_url Application.compile_env(:newspaper_scraper, :la_voz_de_galicia_api_url)

  @middleware [
    Tesla.Middleware.EncodeFormUrlencoded,
    {Tesla.Middleware.BaseUrl, @base_url},
    Tesla.Middleware.FollowRedirects,
    {Tesla.Middleware.Headers,
     [
       {"Content-Type", "application/x-www-form-urlencoded"},
       {"user-agent",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"}
     ]}
  ]

  @client Tesla.client(@middleware)

  # ===================================================================================

  @impl Scraper
  def get_scraper_name, do: @scraper_name

  @impl Scraper
  def get_newspaper_name, do: @newspaper_name

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def scraper_check(url) do
    ScraperCommImpl.comm_scraper_check(url, "lavozdegalicia.es")
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def get_selectors(function) do
    selectors = %{
      parse_search_results: ["#resultPrint"],
      check_premium: [".c-paid.i-access-subscribers"],
      parse_art_header: [".root.container"],
      parse_art_authors: [".data.flex.f-dir-row.f-align-center.mg-t-2"],
      parse_art_date: ["meta"],
      parse_art_body: [".col.sz-dk-67.txt-blk"]
    }

    selectors[function]
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def search_articles(topic, page, limit) do
    # minimum limit is 5
    body =
      Enum.join([
        "pageSize=",
        to_string(limit),
        "&",
        "pageNumber=",
        to_string(page + 1),
        "&",
        "sort=D0003_FECHAPUBLICACION+desc&",
        "doctype=&",
        "dateFrom=&",
        "dateTo=&",
        "edicion=&",
        "formato=&",
        "seccion=&",
        "blog=&",
        "autor=&",
        "source=info&",
        "text=",
        URI.encode(topic)
      ])

    case Tesla.post(@client, @api_url, body) do
      {:ok, res} ->
        handle_response(res)

      {:error, err} ->
        {:error, err}
    end
  end

  defp handle_response(res) do
    case res.status do
      200 -> {:ok, res.body}
      _ -> {:error, res.body}
    end
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def parse_search_results(search_result) do
    selectors = get_selectors(:parse_search_results)

    with {:ok, html} <- Floki.parse_document(search_result),
         {:ok, found_html} <- ParsingUtils.find_element(html, selectors),
         results when is_list(results) <- parse_search_results_html(found_html),
         do: {:ok, results},
         else: (error -> error)
  end

  # -----------------------------------------------------------------------------------

  @spec parse_search_results_html(html :: ScraperParser.html_tree()) ::
          [
            ArticleSummary.t()
          ]
          | {:error, any()}
  defp parse_search_results_html(html) do
    try do
      Floki.traverse_and_update(html, fn
        {"ul", _attrs, children} ->
          children

        {:comment, _comment_data} ->
          nil

        {"li", _attrs, children} ->
          children

        {"header", _attrs, children} ->
          children

        {"h1", [{"itemprop", "headline name"}], children} ->
          children

        {"a", [_itemprop, {"href", raw_url}], children} ->
          [{:url, build_url(raw_url)}, {:title, ParsingUtils.transform_text_children(children)}]

        {"p", [{"itemprop", "alternativeHeadline description"}], [h | _t]} ->
          {:excerpt, Enum.join([ParsingUtils.transform_text_children(h), "..."])}

        {"time", [{"pubdate", _art_date} | _t], _children} ->
          nil

        {"article", [_itemtype, _itemscope, {"class", "hentry "}], children} ->
          {:art_summ, children}

        other ->
          other
      end)
      |> build_article_summs()
    rescue
      _e ->
        {:error, "parsing error"}
    end
  end

  # Article URLs come incomplete
  @spec build_url(raw_url :: String.t()) :: String.t()
  defp build_url(raw_url) do
    Enum.join([@base_url, raw_url])
  end

  # A function for building the Article Summary list
  @spec build_article_summs(raw_art_summs :: list()) :: [
          ArticleSummary.t()
        ]
  defp build_article_summs(raw_art_summs) do
    tasks =
      Enum.map(raw_art_summs, fn
        {:art_summ, contents} ->
          Task.async(fn ->
            contents_map =
              Map.new(contents)

            url = contents_map[:url]

            art_contents_map =
              get_contents_from_art(url)

            %ArticleSummary{
              newspaper: get_newspaper_name(),
              authors: art_contents_map[:authors],
              title: contents_map[:title],
              excerpt: contents_map[:excerpt],
              date_time: art_contents_map[:date_time],
              url: url,
              is_premium: art_contents_map[:is_premium]
            }
          end)
      end)

    Task.await_many(tasks, 20_000)
  end

  # This function parses an article to gather info to improve search results, as the search HTML document
  # does not include it or is incomplete
  defp get_contents_from_art(url) do
    with {:ok, {html_doc, _url}} <- get_article(url),
         {:ok, html} <- Floki.parse_document(html_doc) do
      contents =
        %{}
        |> ParsingUtils.parse(:parse_art_authors, html, LaVozDeGaliciaScraper)
        |> ParsingUtils.parse(:parse_art_date, html, LaVozDeGaliciaScraper)

      Map.put(contents, :is_premium, ParsingUtils.check_premium(html, LaVozDeGaliciaScraper))
    else
      {:error, e} -> {:error, e}
      e -> {:error, e}
    end
  end

  # ===================================================================================

  @impl Scraper
  def get_article(url) do
    case Tesla.get(@client, url) do
      {:ok, res} ->
        {:ok, {transform_body_into_html(res.body), url}}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec transform_body_into_html(body :: binary()) :: String.t()
  defp transform_body_into_html(body) do
    body
    |> :binary.bin_to_list()
    |> List.to_string()
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def parse_article(html_doc, url) do
    ScraperCommImpl.comm_parse_article(html_doc, url, LaVozDeGaliciaScraper)
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_header(parsed_art, html) do
    parsed_title =
      Floki.find(html, ".headline.mg-b-2")
      |> ParsingUtils.transform_text_children()

    parsed_subtitle =
      Floki.find(html, ".subtitle.t-bld")
      |> ParsingUtils.transform_text_children()

    parsed_art
    |> Map.put(:headline, parsed_title)
    |> Map.put(:subheadline, parsed_subtitle)
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_authors(parsed_art, html) do
    parsed_authors =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        {"figure", _attrs, _children} ->
          nil

        {"span", [{"class", "flex"}], children} ->
          children

        {"span", [{"class", class}], children} ->
          case String.contains?(class, "author") do
            true ->
              build_authors(children)

            false ->
              nil
          end

        other ->
          other
      end)

    Map.put(parsed_art, :authors, parsed_authors)
  end

  defp build_authors(children) do
    Enum.map(children, fn
      {"a", [{"href", raw_url}], children} ->
        %Author{
          name: ParsingUtils.transform_text_children(children) |> String.capitalize(),
          url: build_url(raw_url)
        }

      other when is_binary(other) ->
        %Author{
          name: ParsingUtils.transform_text_children(children) |> String.capitalize(),
          url: nil
        }
    end)
  end

  # -----------------------------------------------------------------------------------
  @impl ScraperParser
  def parse_art_date(parsed_art, html) do
    parsed_date_time =
      Floki.traverse_and_update(html, fn
        {"meta", [{"property", "article:published_time"}, {"content", date_time}], _children} ->
          {:date_time, date_time}

        _other ->
          nil
      end)

    Map.put(parsed_art, :date_time, parsed_date_time[:date_time])
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_body(parsed_art, html) do
    parsed_body =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        {"h2", _attrs, children} ->
          %{h2: ParsingUtils.transform_text_children(children)}

        {"h3", _attrs, children} ->
          %{h3: ParsingUtils.transform_text_children(children)}

        {"a", _attrs, children} ->
          children

        {"i", _attrs, children} ->
          children

        {"em", _attrs, children} ->
          children

        {"b", _attrs, children} ->
          children

        {"strong", _attrs, children} ->
          children

        {"p", _attrs, children} ->
          %{p: ParsingUtils.transform_text_children(children)}

        _other ->
          nil
      end)

    Map.put(parsed_art, :body, parsed_body)
  end
end
