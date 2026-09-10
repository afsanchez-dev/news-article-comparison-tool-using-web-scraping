defmodule NewspaperScraper.Boundary.ScraperValidator do
  @moduledoc """
  This module implements the validation functions for the scrapers
  """
  import NewspaperScraper.Boundary.Validator

  @max_limit 10
  @scrapers Application.compile_env(:newspaper_scraper, :scrapers)

  def max_limit, do: @max_limit

  @doc """
  Checks if there are any errors in a search_articles request
  """
  @spec search_articles_errors(fields :: map()) :: :ok | {:error, list()}
  def search_articles_errors(fields) when is_map(fields) do
    []
    |> mandatory(fields, :topic, &validate_topic/1)
    |> mandatory(fields, :page, &validate_page/1)
    |> mandatory(fields, :limit, &validate_limit/1)
    |> has_errors()
  end

  @doc """
  Checks if there are any errors in a get_article request
  """
  @spec get_article_errors(fields :: map()) :: :ok | {:error, list()}
  def get_article_errors(fields) when is_map(fields) do
    []
    |> mandatory(fields, :url, &validate_url/1)
    |> has_errors()
  end

  @spec validate_topic(topic :: any()) :: :ok | any()
  defp validate_topic(topic) when is_binary(topic) do
    check(validate_strings(topic), {:error, "cannot be empty"})
  end

  defp validate_topic(_topic), do: {:error, "must be a binary"}

  @spec validate_page(page :: any()) :: :ok | any()
  defp validate_page(page) when is_integer(page) do
    case check(page >= 0, {:error, "must be greater or equal than 0"}) do
      :ok -> :ok
      error -> error
    end
  end

  defp validate_page(_page), do: {:error, "must be an integer"}

  @spec validate_limit(limit :: any()) :: :ok | any()
  defp validate_limit(limit) when is_integer(limit) do
    with :ok <- check(limit <= @max_limit, {:error, "max. limit exceeded"}),
         :ok <- check(limit > 0, {:error, "must be greater than 0"}),
         do: :ok,
         else: (error -> error)
  end

  defp validate_limit(_limit), do: {:error, "must be an integer"}

  @spec validate_url(url :: any()) :: :ok | any()
  defp validate_url(url) when is_binary(url) do
    with :ok <- check(validate_strings(url), {:error, "cannot be empty"}),
         :ok <- check(validate_newspaper_url(url), {:error, "must be a valid newspaper"}),
         do: :ok,
         else: (error -> error)
  end

  defp validate_url(_url), do: {:error, "must be a binary"}

  # Checks if a String contains any whitespaces with regex
  @spec validate_strings(String.t()) :: true | false
  defp validate_strings(str) do
    not String.match?(str, ~r{^(?=\s*$)})
  end

  # Checks if the url belongs to any scraper
  @spec validate_newspaper_url(url :: any()) :: true | false
  defp validate_newspaper_url(url) do
    checks =
      Enum.map(
        @scrapers,
        fn scraper ->
          scraper.scraper_check(url)
        end
      )

    Enum.member?(checks, {:error, "invalid url"})
  end
end
