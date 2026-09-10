defmodule NewspaperScraper.Core.ScraperParser do
  @moduledoc """
  This module implements the ScraperParser behaviour
  """

  @type selector :: Floki.css_selector()
  @type html_tree :: Floki.html_tree()

  @doc """
  Provides the selectors needed for a specific function
  """
  @callback get_selectors(function :: atom()) :: list(selector()) | nil

  @doc """
  Parses the article header (title and subtitle) and appends the result to the parsed_art map
  """
  @callback parse_art_header(parsed_art :: map(), html :: html_tree()) :: map()

  @doc """
  Parses the article authors and appends the result to the parsed_art map
  """
  @callback parse_art_authors(parsed_art :: map(), html :: html_tree()) :: map()

  @doc """
  Parses the article date and appends the result to the parsed_art map
  """
  @callback parse_art_date(parsed_art :: map(), html :: html_tree()) :: map()

  @doc """
  Parses the article body, filters it and appends the result to the parsed_art map
  """
  @callback parse_art_body(parsed_art :: map(), html :: html_tree()) :: map()
end
