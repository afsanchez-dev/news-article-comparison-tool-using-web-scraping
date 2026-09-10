defmodule TestUtilsTest do
  alias NewspaperScraper.Utils.Test.TestUtils
  use ExUnit.Case, async: true

  @reponses_path Application.compile_env(:newspaper_scraper, :el_pais_search_responses_path)
  @resources_path Application.compile_env(:newspaper_scraper, :el_pais_resources_path)

  describe "read_and_parse_JSON!/2" do
    test "works as expected" do
      exptd_keys = ["search_articles"]
      parsed_json = TestUtils.read_and_parse_JSON!(@reponses_path)
      assert exptd_keys === Map.keys(parsed_json)
    end

    test "should raise an exception when failing" do
      path = Enum.join([@resources_path, "/", "malformed.json"])

      assert_raise(Jason.DecodeError, fn -> TestUtils.read_and_parse_JSON!(path) end)
      assert_raise(File.Error, fn  -> TestUtils.read_and_parse_JSON!(path <> "/nonexisting") end)
    end
  end
end
