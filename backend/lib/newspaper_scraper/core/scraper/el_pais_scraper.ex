defmodule NewspaperScraper.Core.ElPaisScraper do
  @moduledoc """
  This module contains all the logic needed for scraping https://elpais.com
  """
  alias NewspaperScraper.Core.ElPaisScraper
  alias NewspaperScraper.Core.ScraperParser
  alias NewspaperScraper.Core.Scraper
  alias NewspaperScraper.Core.ScraperCommImpl
  alias NewspaperScraper.Utils.Core.ParsingUtils
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Model.Author

  @behaviour Scraper
  @behaviour ScraperParser

  @scraper_name "el-pais"
  @newspaper_name "El País"
  @base_url Application.compile_env(:newspaper_scraper, :el_pais_base_url)
  @api_url Application.compile_env(:newspaper_scraper, :el_pais_api_url)

  @middleware [
    Tesla.Middleware.JSON,
    {Tesla.Middleware.BaseUrl, @base_url},
    Tesla.Middleware.FollowRedirects
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
    ScraperCommImpl.comm_scraper_check(url, "elpais.com")
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def get_selectors(function) do
    selectors = %{
      parse_search_results: [".bu_b"],
      check_premium: ["#ctn_freemium_article", "#ctn_premium_article"],
      parse_art_header: [".a_e_txt", ".articulo-titulares"],
      parse_art_authors: [".a_md_a", ".autor-texto"],
      parse_art_date: [".a_md_f", ".articulo-datos"],
      parse_art_body: [".a_c", ".articulo-cuerpo"]
    }

    selectors[function]
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def search_articles(topic, page, _limit) do
    url =
      Enum.join([@api_url, topic, "/", page + 1])
      |> URI.encode()

    req = Tesla.get(@client, url)

    case req do
      {:ok, res} -> handle_response(res)
      {:error, err} -> {:error, err}
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
        {"div", [{"class", "c_f"}], _children} ->
          nil

        {"div", [{"class", "c_a"}], children} ->
          {:authors, build_search_authors(children)}

        {"p", [{"class", "c_d"}], children} ->
          {:excerpt, ParsingUtils.transform_text_children(children)}

        {"div", _attrs, children} ->
          children

        {"header", _attrs, children} ->
          children

        {"h2", _attrs, [{"a", [{"href", url}], children}]} ->
          [{:url, url}, {:title, ParsingUtils.transform_text_children(children)}]

        {"article", [_class, _timestamp, {"datetime", datetime}], children} ->
          {:art_summ, [{:date_time, datetime} | children]}

        {"figure", _attrs, _children} ->
          nil

        {"span", _attrs, _children} ->
          nil

        {"a", [{"class", _classname}, _href], _children} ->
          nil

        other ->
          other
      end)
      |> build_article_summs()
    rescue
      _e ->
        {:error, "parsing error"}
    end
  end

  # This function helps building the search results authors
  @spec build_search_authors(children :: ScraperParser.html_tree()) :: list(Author.t())
  defp build_search_authors(children) do
    Enum.map(children, fn
      {"a", [{"href", url}, _class], children} ->
        %Author{
          name: ParsingUtils.transform_text_children(children),
          url: url
        }

      _other ->
        nil
    end)
    |> Enum.filter(fn data -> data !== nil end)
  end

  # A function for building the Article Summary list
  @spec build_article_summs(raw_art_summs :: list()) :: [
          ArticleSummary.t()
        ]
  defp build_article_summs(raw_art_summs) do
    raw_art_summs = Enum.take(raw_art_summs, 6)

    tasks =
      Enum.map(raw_art_summs, fn
        {:art_summ, contents} ->
          Task.async(fn ->
            contents_map =
              Map.new(contents)

            url = contents_map[:url]

            %ArticleSummary{
              newspaper: get_newspaper_name(),
              authors: contents_map[:authors],
              title: contents_map[:title],
              excerpt: contents_map[:excerpt],
              date_time: contents_map[:date_time],
              url: url,
              is_premium: ParsingUtils.search_check_premium(url, ElPaisScraper)
            }
          end)
      end)

    Task.await_many(tasks, 20_000)
  end

  # ===================================================================================

  @impl Scraper
  def get_article(url) do
    ScraperCommImpl.comm_get_article(@client, url)
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def parse_article(html_doc, url) do
    ScraperCommImpl.comm_parse_article(html_doc, url, ElPaisScraper)
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_header(parsed_art, html) do
    parsed_header =
      Floki.traverse_and_update(html, fn
        {"h1", _attrs, children} ->
          {:headline, ParsingUtils.transform_text_children(children)}

        {"h2", _attrs, children} ->
          {:subheadline, ParsingUtils.transform_text_children(children)}

        {_other, _attrs, children} ->
          children

        _other ->
          nil
      end)

    parsed_art
    |> Map.put(:headline, parsed_header[:headline])
    |> Map.put(:subheadline, parsed_header[:subheadline])
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_authors(parsed_art, html) do
    parsed_authors =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        # When author has url
        {"a", attrs, children} ->
          transformed_attrs = ParsingUtils.transform_attributes(attrs)
          url = transformed_attrs["href"]

          %Author{
            name: ParsingUtils.transform_text_children(children),
            url: build_author_url(url)
          }

        {"span", [{"class", "autor-nombre"} | _r_attrs], children} ->
          children

        # When author doesn't have url
        {"span", _attrs, children} ->
          %Author{
            name: ParsingUtils.transform_text_children(children),
            url: nil
          }

        _other ->
          nil
      end)

    Map.put(parsed_art, :authors, parsed_authors)
  end

  # Builds the author url in case it comes incomplete
  @spec build_author_url(url :: String.t()) :: String.t()
  defp build_author_url(url) do
    case String.contains?(url, @base_url) do
      true -> url
      # TODO check if this is correct (maybe bug)
      false -> "https://" <> @base_url <> url
    end
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_date(parsed_art, html) do
    parsed_date_time =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        {"span", children} ->
          children

        {"time", attrs, _children} ->
          transformed_attrs = ParsingUtils.transform_attributes(attrs)
          date_time = transformed_attrs["datetime"]
          {:date_time, date_time}

        {_other, _attrs, children} ->
          children

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
        # Avoids picking more content than needed in live articles
        {"div", [{"id", "les"}], _children} ->
          nil

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
      |> filter_body_content()

    Map.put(parsed_art, :body, parsed_body)
  end

  # -----------------------------------------------------------------------------------

  # Filters unwanted content out from the parsed body
  @spec filter_body_content(body :: list()) :: list()
  defp filter_body_content(body) do
    Enum.filter(body, fn
      %{p: ""} ->
        false

      %{p: nil} ->
        false

      %{p: text} ->
        not (String.contains?(text, "Sigue toda la información de Cinco Días") or
               String.contains?(text, "newsletter") or
               String.contains?(text, "EL PAÍS") or
               String.contains?(text, "Publicaciones nuevas") or
               String.contains?(text, "seguir") or
               String.contains?(text, "suscríbete"))

      text ->
        not is_binary(text)
    end)
  end
end
