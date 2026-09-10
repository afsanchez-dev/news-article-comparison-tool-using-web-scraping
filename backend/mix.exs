defmodule NewspaperScraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :newspaper_scraper,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: test_coverage()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NewspaperScraper.Application, [env: Mix.env()]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.34.3"},
      {:tesla, "~> 1.7"},
      {:jason, "~> 1.4.1"},
      {:gen_stage, "~> 1.2"},
      {:plug_cowboy, "~> 2.6"},
      {:cors_plug, "~> 3.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30.9", only: :dev, runtime: false},
      {:codepagex, "~> 0.1.6"}
    ]
  end

  defp aliases do
    [
      test: "test --trace --cover"
    ]
  end

  defp test_coverage do
    [
      ignore_modules: [
        NewspaperScraper.Application,
        NewspaperScraper.Mocks.ElPaisMockServer,
        NewspaperScraper.Mocks.ElMundoMockServer,
        NewspaperScraper.Core.Scraper,
        NewspaperScraper.Model.Article,
        NewspaperScraper.Model.ArticleSummary,
        NewspaperScraper.Model.Author,
        NewspaperScraper.Model.AppError,
        NewspaperScraper.Tools.ManualScraperResultChecker,
        Jason.Encoder.NewspaperScraper.Model.Article,
        Jason.Encoder.NewspaperScraper.Model.ArticleSummary,
        Jason.Encoder.NewspaperScraper.Model.Author
      ]
    ]
  end
end
