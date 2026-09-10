defmodule NewspaperScraper.Boundary.ScraperManager do
  @moduledoc """
  This module contains all the logic needed for generating requests for the scraper stages
  """
  alias NewspaperScraper.Boundary.Managers.ScraperEventManager
  alias NewspaperScraper.Boundary.Managers.ScraperRequestHandler
  alias NewspaperScraper.Boundary.Managers.ScraperParsingHandlerSupervisor
  use GenServer

  require Logger

  @timeout 30_000

  # ===================================================================================

  @doc """
  Starts a link with a ScraperManager process
  """
  @spec start_link(opts :: list()) :: {:ok, pid()} | {:error, any()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:args], opts)
  end

  # ---------------------------------------------------------------------------------

  @doc """
  Calls the ScraperManager GenServer for searching articles
  """
  @spec search_articles(
          manager :: module() | atom(),
          topic :: String.t(),
          page :: integer(),
          limit :: integer()
        ) :: term()
  def search_articles(manager \\ __MODULE__, topic, page, limit) do
    req = %{
      topic: topic,
      page: page,
      limit: limit
    }

    GenServer.call(manager, {:search_articles, req}, @timeout)
  end

  # ---------------------------------------------------------------------------------

  @doc """
  Calls the ScraperManager GenServer for getting articles
  """
  @spec get_article(manager :: module() | atom(), url :: String.t()) :: term()
  def get_article(manager \\ __MODULE__, url) do
    req = %{
      url: url
    }

    GenServer.call(manager, {:get_article, req}, @timeout)
  end

  # ===================================================================================

  # Builds children for the supervisor created when starting the GenServer
  @spec build_children(num_req_handlers :: integer()) :: list()
  defp build_children(num_req_handlers) do
    {req_handlers, names} = build_req_handlers(num_req_handlers)

    [{ScraperEventManager, []}] ++
      req_handlers ++
      [{ScraperParsingHandlerSupervisor, subscription_names: names}]
  end

  # ---------------------------------------------------------------------------------

  # Builds ScraperRequestHandler names for further subscriptions
  @spec build_req_handlers(num_req_handlers :: integer()) :: tuple()
  defp build_req_handlers(num_req_handlers) do
    names =
      for num <- 1..num_req_handlers do
        (to_string(ScraperRequestHandler) <> "_" <> to_string(num))
        |> String.to_atom()
      end

    children =
      Enum.map(
        names,
        fn name ->
          Supervisor.child_spec({ScraperRequestHandler, name: name}, id: name)
        end
      )

    {children, names}
  end

  # ===================================================================================
  # GenServer Callbacks
  # ===================================================================================

  @impl true
  def init(args) do
    Logger.info("ScraperManager is ready")

    num_req_handlers = args[:num_req_handlers]

    try do
      children = build_children(num_req_handlers)
      Supervisor.start_link(children, strategy: :rest_for_one)
    rescue
      e -> {:stop, e.message}
    end
  end

  # ---------------------------------------------------------------------------------

  @impl true
  def handle_call({:search_articles, req}, from, state) do
    ScraperEventManager.push_event({:search_articles, req: req, client: from})

    {:noreply, state}
  end

  # ---------------------------------------------------------------------------------

  @impl true
  def handle_call({:get_article, req}, from, state) do
    ScraperEventManager.push_event({:get_article, req: req, client: from})

    {:noreply, state}
  end

  # ---------------------------------------------------------------------------------

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # ---------------------------------------------------------------------------------

  @impl true
  def terminate(reason, state) do
    Logger.alert(%{message: "ScraperManager terminated", reason: reason, state: state})
  end
end
