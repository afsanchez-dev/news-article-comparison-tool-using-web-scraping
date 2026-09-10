alias NewspaperScraper.Core.ElPaisScraper
alias NewspaperScraper.Core.ElMundoScraper
alias NewspaperScraper.Core.LaVozDeGaliciaScraper

import Config

config :newspaper_scraper,
  el_pais_base_url: "https://elpais.com",
  el_pais_api_url: "/buscador/",
  el_mundo_base_url: "https://www.elmundo.es/",
  el_mundo_api_url: "https://ariadna.elmundo.es/buscador/archivo.html",
  la_voz_de_galicia_base_url: "https://www.lavozdegalicia.es",
  la_voz_de_galicia_api_url: "/buscador/q/",
  scrapers: [
    ElMundoScraper,
    ElPaisScraper,
    LaVozDeGaliciaScraper
  ]
