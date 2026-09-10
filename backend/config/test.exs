alias NewspaperScraper.Core.ElPaisScraper
import Config

config :newspaper_scraper,
  # El País config
  el_pais_base_url: "http://localhost:8081",
  el_pais_api_url: "/search_articles",
  el_pais_resources_path: "./priv/test/el_pais",
  el_pais_search_responses_path: "./priv/test/el_pais/el_pais_search_responses.json",
  # El Mundo config
  el_mundo_base_url: "http://localhost:8082",
  el_mundo_api_url: "http://localhost:8082/search_articles",
  el_mundo_search_responses_path: "./priv/test/el_mundo/search_responses",
  el_mundo_articles_path: "./priv/test/el_mundo/articles",
  # General config
  scrapers: [
    ElPaisScraper
  ]
