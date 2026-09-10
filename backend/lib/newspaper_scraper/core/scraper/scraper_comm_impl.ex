defmodule NewspaperScraper.Core.ScraperCommImpl do
  @moduledoc """
  Common implementations for some of the scrapers' functionalities
  """
  alias NewspaperScraper.Utils.Core.ParsingUtils
  alias NewspaperScraper.Core.ScraperParser
  alias NewspaperScraper.Model.Article

  @doc """
  Common implementation for Scraper.scraper_check function
  """
  @spec comm_scraper_check(url :: String.t(), base_url :: String.t()) ::
          :ok | {:error, String.t()}
  def comm_scraper_check(url, base_url) do
    case String.contains?(url, base_url) do
      true -> :ok
      false -> {:error, "invalid url"}
    end
  end

  @doc """
  Common implementation for Scraper.get_article function
  """
  @spec comm_get_article(client :: Tesla.Client.t(), url :: String.t()) ::
          {:ok, {html_doc :: String.t(), url :: String.t()}} | {:error, any()}
  def comm_get_article(client, url) do
    case Tesla.get(client, url) do
      {:ok, res} -> {:ok, {res.body, url}}
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Common implementation for Scraper.parse_article function
  """
  @spec comm_parse_article(html_doc :: String.t(), url :: String.t(), scraper :: module()) ::
          {:ok, Article.t()} | {:error, any()}
  def comm_parse_article(html_doc, url, scraper) do
    with {:ok, html} <- Floki.parse_document(html_doc),
         false <- ParsingUtils.check_premium(html, scraper),
         {:ok, parsed_html} <- ParsingUtils.html_to_article(html, url, scraper) do
      {:ok, parsed_html}
    else
      {:error, e} -> {:error, e}
      true -> {:error, "forbidden content"}
    end
  end

  @doc """
  Common implementation for Scraper.parse_art_date
  """
  @spec comm_parse_art_date(parsed_art :: map(), html :: ScraperParser.html_tree()) :: map()
  def comm_parse_art_date(parsed_art, html) do
    parsed_date_time =
      Floki.traverse_and_update(html, fn
        {"time", attrs, _children} ->
          transformed_attrs = ParsingUtils.transform_attributes(attrs)
          date_time = transformed_attrs["datetime"]
          ParsingUtils.parse_article_date_time(date_time)

        {_other, _attrs, children} ->
          children

        _other ->
          nil
      end)

    Map.put(parsed_art, :date_time, parsed_date_time[:date_time])
  end
end
