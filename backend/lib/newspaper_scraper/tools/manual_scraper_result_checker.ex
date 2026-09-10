defmodule NewspaperScraper.Tools.ManualScraperResultChecker do
  # credo:disable-for-this-file
  @moduledoc """
  This module implements tools for testing scraper results manually.

  It is meant to be used for easily checking results.
  """
  alias NewspaperScraper.Utils.Core.ParsingUtils

  @doc """
  Chooses a random topic and performs a search in the scraper passed as an argument
  """
  @spec test(scraper :: module()) :: map()
  def test(scraper) do
    {:ok, html} =
      [
        "palestina",
        "cataluña",
        "política España",
        "política internacional",
        "Pedro Sánchez",
        "ucrania",
        "economía",
        "milei",
        "nuevas tecnologías",
        "biotecnología",
        "robotización",
        "cambio climático"
      ]
      |> Enum.random()
      |> scraper.search_articles(0, 5)
      |> Tuple.to_list()
      |> Enum.at(1)
      |> scraper.parse_search_results()
      |> Tuple.to_list()
      |> Enum.at(1)
      |> Enum.filter(fn res -> res.is_premium === false end)
      |> Enum.random()
      |> Map.get(:url)
      |> dbg()
      |> scraper.get_article()
      |> Tuple.to_list()
      |> Enum.at(1)
      |> Tuple.to_list()
      |> Enum.at(0)
      |> Floki.parse_document()

    parse_results(html, scraper)
  end

  @doc """
  Parses an article by its url
  """
  @spec test_url(url :: String.t(), scraper :: module()) :: map()
  def test_url(url, scraper) do
    {:ok, html} =
      scraper.get_article(url)
      |> Tuple.to_list()
      |> Enum.at(1)
      |> Tuple.to_list()
      |> Enum.at(0)
      |> Floki.parse_document()

    parse_results(html, scraper)
  end

  # Parses results if the article is not premium
  defp parse_results(html, scraper) do
    case ParsingUtils.check_premium(html, scraper) do
      true ->
        {:error, "forbidden content"}

      false ->
        %{}
        |> ParsingUtils.parse(:parse_art_header, html, scraper)
        |> ParsingUtils.parse(:parse_art_authors, html, scraper)
        |> ParsingUtils.parse(:parse_art_date, html, scraper)
        |> ParsingUtils.parse(:parse_art_body, html, scraper)
    end
  end
end
