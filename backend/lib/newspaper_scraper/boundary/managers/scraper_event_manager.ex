defmodule NewspaperScraper.Boundary.Managers.ScraperEventManager do
  @moduledoc """
  This module contains all the logic for spreading events to the rest of the stages
  """
  require Logger
  use GenStage

  @doc """
  Starts a link with a ScraperEventManager process
  """
  @spec start_link(opts :: list()) :: {:ok, pid()} | {:error, any()}
  def start_link(_args) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Calls the ScraperEventManager GenStage to push a new event into the internal queue
  """
  @spec push_event(event :: tuple(), timeout()) :: term()
  def push_event(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:push, event}, timeout)
  end

  @doc """
  Sends events to the next stage when demand exists
  """
  @spec dispatch_events(
          queue :: :queue.queue() | :queue.queue(tuple()),
          demand :: integer(),
          events :: list()
        ) :: tuple()
  def dispatch_events(queue, demand, events) do
    with d when d > 0 <- demand,
         {item, queue} = :queue.out(queue),
         {:value, {from, event}} <- item do
      GenStage.reply(from, :ok)
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end

  # GenStage Callbacks

  @impl true
  def init(:ok) do
    Logger.info("ScraperEventManager is ready")
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.DemandDispatcher}
  end

  @impl true
  def handle_call({:push, event}, from, {queue, pending_demand}) do
    dispatch_events(:queue.in({from, event}, queue), pending_demand, [])
  end

  @impl true
  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end
end
