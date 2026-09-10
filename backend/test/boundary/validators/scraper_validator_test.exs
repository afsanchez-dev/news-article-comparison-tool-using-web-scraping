defmodule Boundary.Validators.ScraperValidatorTest do
  alias NewspaperScraper.Boundary.ScraperValidator
  use ExUnit.Case, async: true

  # ===================================================================================

  describe "search_articles_errors/1" do
    test "should fail when no fields are given" do
      fields = %{}
      msg = "is mandatory"

      assert {:error, [topic: t_err, page: p_err, limit: l_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert t_err === msg
      assert p_err === msg
      assert l_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when one field is not given" do
      fields = %{page: 1, limit: 2}
      msg = "is mandatory"

      assert {:error, [topic: t_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert t_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when topic type incorrect" do
      fields = %{topic: 2, page: 1, limit: 2}
      msg = "must be a binary"

      assert {:error, [topic: t_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert t_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when topic is empty" do
      empty_topic = %{topic: "", page: 1, limit: 2}
      blank_topic = %{topic: "     ", page: 1, limit: 2}
      msg = "cannot be empty"

      assert {:error, [topic: e_t_err]} =
               ScraperValidator.search_articles_errors(empty_topic)

      assert {:error, [topic: b_t_err]} =
               ScraperValidator.search_articles_errors(blank_topic)

      assert e_t_err === msg
      assert b_t_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when page and limit types incorrect" do
      fields = %{topic: "any", page: "hello", limit: [:world]}
      msg = "must be an integer"

      assert {:error, [page: p_err, limit: l_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert p_err === msg
      assert l_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when max. limit is exceeded" do
      fields = %{topic: "any", page: 1, limit: ScraperValidator.max_limit() + 1}
      msg = "max. limit exceeded"

      assert {:error, [limit: l_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert l_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when page is negative" do
      fields = %{topic: "any", page: -1, limit: 2}
      msg = "must be greater or equal than 0"

      assert {:error, [page: p_err]} =
               ScraperValidator.search_articles_errors(fields)

      assert p_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "works when types and format correct" do
      fields = %{topic: "any", page: 1, limit: ScraperValidator.max_limit()}

      assert :ok === ScraperValidator.search_articles_errors(fields)
    end
  end

  # ===================================================================================

  describe "get_article_errors/1" do
    test "should fail when no fields are given" do
      fields = %{}
      msg = "is mandatory"

      assert {:error, [url: u_err]} =
               ScraperValidator.get_article_errors(fields)

      assert u_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when url type incorrect" do
      fields = %{url: [:hello, :world]}
      msg = "must be a binary"

      assert {:error, [url: u_err]} =
               ScraperValidator.get_article_errors(fields)

      assert u_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when url is empty" do
      empty_url = %{url: ""}
      blank_url = %{url: "     "}
      msg = "cannot be empty"

      assert {:error, [url: e_u_err]} =
               ScraperValidator.get_article_errors(empty_url)

      assert {:error, [url: b_u_err]} =
               ScraperValidator.get_article_errors(blank_url)

      assert e_u_err === msg
      assert b_u_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should fail when url is invalid" do
      fields = %{url: "https://udc.es"}
      msg = "must be a valid newspaper"

      assert {:error, [url: u_err]} =
               ScraperValidator.get_article_errors(fields)

      assert u_err === msg
    end

    # ---------------------------------------------------------------------------------

    test "should work when url is correct" do
      url = "https://elpais.com"

      fields = %{url: url}

      assert :ok === ScraperValidator.get_article_errors(fields)
    end
  end
end
