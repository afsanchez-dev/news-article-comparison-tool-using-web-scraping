defmodule NewspaperScraper.Boundary.Managers.ScraperParsingHandler do
  @moduledoc """
  This module contains the logic for parsing results from requests
  """
  alias NewspaperScraper.Model.AppError
  alias NewspaperScraper.Model.Article
  require Logger

  @doc """
  Starts a link with a ScraperParsingHandler process
  """
  @spec start_link(
          event ::
            {:parse_search_results, res: list(map()), client: pid}
            | {:parse_article, res: html_doc :: binary(), client: pid()}
        ) :: {:ok, pid()}
  def start_link(event) do
    Task.start_link(fn ->
      event
      |> parse_responses()
      |> handle_reply()
    end)
  end

  @doc """
  Handles reply to the client
  """
  @spec handle_reply({any(), keyword()}) :: :ok
  def handle_reply({_res_type, res}) do
    client = res[:client]
    parsed_content = res[:parsed]
    GenServer.reply(client, parsed_content)
  end

  @doc """
  Parses both types of results from the requests
  """
  @spec parse_responses(
          {:parse_search_results, res: {:ok, keyword()}, client: pid()}
          | {:parse_article, res: {:ok, keyword()} | {:error, any()}, client: pid()}
        ) ::
          {:parsed_art_summs, parsed: list(map()) | {:error, any()}, client: pid()}
          | {:parsed_art, parsed: {:ok, Article.t()} | {:error, any()}, client: pid()}
  def parse_responses({:parse_search_results, res: res, client: client}) do
    parsed_art_summs =
      Enum.map(res, &parse_search_results/1)

    {:parsed_art_summs, parsed: parsed_art_summs, client: client}
  end

  def parse_responses({:parse_article, res: res, client: client}) do
    parsed_art =
      case res do
        {:ok, scraper: scraper, raw_art: raw_article, url: url} ->
          case scraper.parse_article(raw_article, url) do
            {:ok, parsed_art} -> {:ok, parsed_art}
            error -> error
          end

        {:error, e} ->
          {:error, e}
      end

    {:parsed_art, parsed: parsed_art, client: client}
  end

  # Auxiliar function for parsing search results
  defp parse_search_results(res) do
    case res do
      {:ok, scraper: scraper, results: raw_art_summs} ->
        case scraper.parse_search_results(raw_art_summs) do
          {:ok, parsed_art} ->
            %{scraper: scraper.get_scraper_name(), results: parsed_art}

          {:error, error} ->
            %{scraper: scraper.get_scraper_name(), results: build_search_error({:error, error})}
        end

      {:error, scraper: scraper, results: error} ->
        %{scraper: scraper.get_scraper_name(), results: build_search_error(error)}
    end
  end

  # Auxiliar function for builing errors
  defp build_search_error({:error, error}) do
    %AppError{
      error: error
    }
  end
end
