defmodule NewspaperScraper.Boundary.ScraperAPI do
  @moduledoc """
  This module implements the API for scrapers
  """
  alias NewspaperScraper.Model.Article
  alias NewspaperScraper.Boundary.ScraperValidator
  alias NewspaperScraper.Boundary.ScraperManager

  @doc """
  Validates request content and search articles
  """
  @spec search_articles(map()) :: list() | {:error, any()}
  def search_articles(request) do
    with :ok <- ScraperValidator.search_articles_errors(request),
         parsed_art_summs when is_list(parsed_art_summs) <-
           ScraperManager.search_articles(
             request.topic,
             request.page,
             request.limit
           ),
         do: parsed_art_summs,
         else: (error -> error)
  end

  @doc """
  Validates request content and get articles
  """
  @spec get_article(map()) :: {:ok, Article.t()} | {:error, any()}
  def get_article(request) do
    with :ok <- ScraperValidator.get_article_errors(request),
         {:ok, parsed_art} <- ScraperManager.get_article(request.url),
         do: {:ok, parsed_art},
         else: (error -> error)
  end
end
