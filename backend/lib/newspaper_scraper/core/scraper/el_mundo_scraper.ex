defmodule NewspaperScraper.Core.ElMundoScraper do
  @moduledoc """
  This module contains all the logic needed for scraping https://www.elmundo.es/
  """
  alias NewspaperScraper.Core.ElMundoScraper
  alias NewspaperScraper.Core.ScraperParser
  alias NewspaperScraper.Core.Scraper
  alias NewspaperScraper.Utils.Core.ParsingUtils
  alias NewspaperScraper.Core.ScraperCommImpl
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Model.Author

  @behaviour Scraper
  @behaviour ScraperParser

  @scraper_name "el-mundo"
  @newspaper_name "El Mundo"

  @api_url Application.compile_env(:newspaper_scraper, :el_mundo_api_url)

  # Add the user-agent header to avoid server rejection
  @middleware [
    Tesla.Middleware.FollowRedirects,
    {Tesla.Middleware.Headers,
     [
       {"user-agent",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"},
       {"accept", "text/html"}
     ]},
    Tesla.Middleware.DecompressResponse
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
    ScraperCommImpl.comm_scraper_check(url, "elmundo.es")
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def get_selectors(function) do
    selectors = %{
      parse_search_results: [".lista_resultados"],
      check_premium: [".ue-c-article__premium-tag"],
      parse_art_header: [".ue-c-article"],
      parse_art_authors: [".ue-c-article__author-name", ".ue-c-article__byline-name"],
      parse_art_date: [".ue-c-article__publishdate"],
      parse_art_body: [".ue-l-article__body"]
    }

    selectors[function]
  end

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def search_articles(topic, page, limit) do
    req_page =
      page * limit + 1

    try do
      #  Transform it to latin1 encoding for elmundo server to understand
      {:ok, parsed_topic} = Codepagex.from_string(topic, :iso_8859_1)

      request = [
        q: parsed_topic,
        t: 1,
        # Index
        i: req_page,
        n: limit,
        fd: 0,
        td: 0,
        #  Coincidence ratio
        w: 80,
        #  Order by date = 1, order by coincidence = 0
        s: 1,
        no_acd: 1,
        b_avanzada: "elmundoes"
      ]

      url =
        Tesla.build_url(@api_url, request)

      case Tesla.get(@client, url) do
        {:ok, res} ->
          handle_response(res)

        {:error, err} ->
          {:error, err}
      end
    rescue
      err -> {:error, err}
    end
  end

  defp handle_response(res) do
    case res.status do
      200 -> {:ok, transform_body_into_html(res.body)}
      _ -> {:error, res.body}
    end
  end

  # Response comes in binary, so we transform it into a string
  @spec transform_body_into_html(body :: binary()) :: String.t()
  defp transform_body_into_html(body) do
    body
    |> :binary.bin_to_list()
    |> List.to_string()
    |> String.replace(~r/\n/, "")
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

  # Auxiliar function for parsing search results
  @spec parse_search_results_html(html :: ScraperParser.html_tree()) ::
          [
            ArticleSummary.t()
          ]
          | {:error, any()}
  defp parse_search_results_html(html) do
    try do
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        {"ul", _attrs, children} ->
          children

        {"li", _attrs, []} ->
          nil

        {"li", _attrs, [{:date, date_str} | t]} ->
          [{:date, date_str} | t]

        {"li", [], children} ->
          {:art_summ, children}

        {"h2", _attrs, _children} ->
          nil

        {"h3", _attrs, children} ->
          children

        {"a", [{"href", url}], children} ->
          [{:url, url}, {:title, ParsingUtils.transform_text_children(children)}]

        {"p", [], children} ->
          {:excerpt, ParsingUtils.transform_text_children(children)}

        {"p", _attrs, _children} ->
          nil

        {"span", [{"class", "fecha"}], [_date]} ->
          nil

        {"span", [{"class", "firma"}], children} ->
          children

        {"strong", [{"class", "autor"}], [_author_name]} ->
          nil

        {"strong", [], [children]} ->
          children

        {"strong", _attrs, _children} ->
          nil

        {:comment, _comment} ->
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

    res = Task.await_many(tasks, 20_000)

    case res do
      [] -> {:error, "not_found"}
      _other -> res
    end
  end

  # This function parses an article to gather info to improve search results, as the search HTML document
  # does not include it or is incomplete
  defp get_contents_from_art(url) do
    with {:ok, {html_doc, _url}} <- get_article(url),
         {:ok, html} <- Floki.parse_document(html_doc) do
      contents =
        %{}
        |> ParsingUtils.parse(:parse_art_authors, html, ElMundoScraper)
        |> ParsingUtils.parse(:parse_art_date, html, ElMundoScraper)

      Map.put(contents, :is_premium, ParsingUtils.check_premium(html, ElMundoScraper))
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

  # -----------------------------------------------------------------------------------

  @impl Scraper
  def parse_article(html_doc, url) do
    ScraperCommImpl.comm_parse_article(html_doc, url, ElMundoScraper)
  end

  # -----------------------------------------------------------------------------------

  @spec find_and_parse_text(
          html :: Floki.html_tree(),
          selectors :: list(Floki.css_selector())
        ) :: content :: String.t()
  defp find_and_parse_text(html, selectors) do
    case ParsingUtils.find_element(html, selectors) do
      {:error, _e} -> nil
      {:ok, found_html} -> ParsingUtils.transform_text_children(found_html)
    end
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_header(parsed_art, html) do
    parsed_header =
      [
        {:headline, find_and_parse_text(html, [".ue-c-article__headline"])},
        {:subheadline,
         find_and_parse_text(html, [
           ".ue-c-article__standfirst",
           ".ue-c-article__card-body"
         ])}
      ]

    parsed_art
    |> Map.put(:headline, parsed_header[:headline])
    |> Map.put(:subheadline, parsed_header[:subheadline])
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_authors(parsed_art, html) do
    parsed_authors =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, [h | t]} ->
          if is_binary(h) do
            build_no_url_author(h)
          else
            [h | t]
          end

        {"a", attrs, children} ->
          transformed_attrs = ParsingUtils.transform_attributes(attrs)
          url = transformed_attrs["href"]

          name =
            ParsingUtils.transform_text_children(children)
            |> ParsingUtils.normalize_name()

          %Author{
            name: name,
            url: url
          }

        {"span", _attrs, _children} ->
          nil

        other ->
          build_no_url_author(other)
      end)

    Map.put(parsed_art, :authors, parsed_authors)
  end

  defp build_no_url_author(auth_name) do
    %Author{
      name: ParsingUtils.normalize_name(auth_name),
      url: nil
    }
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_date(parsed_art, html) do
    ScraperCommImpl.comm_parse_art_date(parsed_art, html)
  end

  # -----------------------------------------------------------------------------------

  @impl ScraperParser
  def parse_art_body(parsed_art, html) do
    parsed_body =
      Floki.traverse_and_update(html, fn
        {"div", _attrs, children} ->
          children

        {"dl", _attrs, children} ->
          children

        {"dt", _attrs, children} ->
          %{p: ParsingUtils.transform_text_children(children)}

        {"dd", _attrs, children} ->
          %{p: ParsingUtils.transform_text_children(children)}

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

  # Filters unwanted content out from the parsed body
  @spec filter_body_content(body :: list()) :: list()
  defp filter_body_content(body) do
    Enum.filter(body, fn
      content when is_map(content) ->
        case Map.values(content) do
          [""] -> false
          [nil] -> false
          _other -> true
        end

      text ->
        not is_binary(text)
    end)
  end
end
