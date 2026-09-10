defmodule NewspaperScraper.Utils.Test.TestUtils do
  @moduledoc """
  Utilities for testing
  """

  @doc """
  Reads and parses a JSON file
  """
  @spec read_and_parse_JSON!(Path.t(), list()) :: map()
  def read_and_parse_JSON!(file_path, opts \\ []) do
    body = File.read!(file_path)

    Jason.decode!(body, opts)
  end
end
