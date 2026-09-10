defmodule NewspaperScraper.Utils.Routes.RouterUtilsTest do
  alias NewspaperScraper.Utils.Routes.RouterUtils
  use ExUnit.Case, async: true

  describe "transform_error/1" do
    test "transforms errors properly" do
      string_error = {:error, "test error"}
      atom_error = {:error, :forbbiden_content}
      keyword_error = {:error, topic: "topic must be a string", page: "page must be an integer"}

      exptd_string_error = %{error: "test error"}
      exptd_atom_error = %{error: :forbbiden_content}

      exptd_keyword_error = %{
        error: [%{topic: "topic must be a string"}, %{page: "page must be an integer"}]
      }

      assert exptd_string_error === RouterUtils.transform_error(string_error)
      assert exptd_atom_error === RouterUtils.transform_error(atom_error)
      assert exptd_keyword_error === RouterUtils.transform_error(keyword_error)
    end
  end

  describe "transform_query_params/1" do
    test "transforms query params properly" do
      empty_params = %{}

      complete_search_articles_params = %{
        "topic" => "testTopic",
        "page" => "testPage",
        "limit" => "testLimit"
      }

      partial_search_articles_params = %{
        "topic" => "testTopic",
        "limit" => "testLimit"
      }

      complete_get_article_params = %{"url" => "testUrl"}

      exptd_empty_params_transform = %{}

      exptd_complete_search_articles_params = %{
        topic: "testTopic",
        page: "testPage",
        limit: "testLimit"
      }

      exptd_partial_search_articles_params = %{
        topic: "testTopic",
        limit: "testLimit"
      }

      exptd_complete_get_article_params = %{url: "testUrl"}

      assert exptd_empty_params_transform ===
               RouterUtils.transform_query_params(empty_params)

      assert exptd_complete_search_articles_params ===
               RouterUtils.transform_query_params(complete_search_articles_params)

      assert exptd_partial_search_articles_params ===
               RouterUtils.transform_query_params(partial_search_articles_params)

      assert exptd_complete_get_article_params ===
               RouterUtils.transform_query_params(complete_get_article_params)
    end
  end
end
