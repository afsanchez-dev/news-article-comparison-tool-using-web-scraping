defmodule NewspaperScraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias NewspaperScraper.Boundary.Routes.ScraperRouter
  alias NewspaperScraper.Boundary.ScraperManager
  alias NewspaperScraper.Mocks.ElPaisMockServer
  alias NewspaperScraper.Mocks.ElMundoMockServer

  require Logger

  use Application

  @impl true
  def start(_type, args) do
    Logger.info("Starting Application...")

    children =
      case args do
        [env: :prod] ->
          []

        [env: :test] ->
          [
            {Plug.Cowboy, scheme: :http, plug: ElPaisMockServer, options: [port: 8081]},
            {Plug.Cowboy, scheme: :http, plug: ElMundoMockServer, options: [port: 8082]}
          ]

        [env: :dev] ->
          Logger.info("Server running on: http://localhost:8080")

          [
            {Plug.Cowboy, scheme: :http, plug: ScraperRouter, options: [port: 8080]},
            {ScraperManager, [name: ScraperManager, args: [num_req_handlers: 4]]}
          ]

        [_] ->
          []
      end

    opts = [strategy: :one_for_one, name: NewspaperScraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
