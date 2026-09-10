defmodule NewspaperScraper.Core.Scraper do
  @moduledoc """
  This module implements the scraper behaviour
  """
  alias NewspaperScraper.Model.ArticleSummary
  alias NewspaperScraper.Model.Article

  @doc """
  Returns the name of the scraper
  """
  @callback get_scraper_name() :: String.t()

  @doc """
  Returns the name of the newspaper
  """
  @callback get_newspaper_name() :: String.t()

  @doc """
  Checks if the url belongs to the scraper
  """
  @callback scraper_check(url :: String.t()) :: :ok | {:error, any()}

  @doc """
  Searches articles based on a topic
  """
  @callback search_articles(topic :: String.t(), page :: integer(), limit :: integer()) ::
              {:ok, any()} | {:error, any()}

  @doc """
  Parses search results
  """
  @callback parse_search_results(articles :: any()) ::
              {:ok, list(ArticleSummary.t())} | {:error, any()}

  @doc """
  Requests the article HTML
  """
  @callback get_article(url :: String.t()) ::
              {:ok, {html_doc :: String.t(), url :: String.t()}} | {:error, any()}

  @doc """
  Parses the article HTML
  """
  @callback parse_article(article :: String.t(), url :: String.t()) ::
              {:ok, Article.t()} | {:error, any()}
end
