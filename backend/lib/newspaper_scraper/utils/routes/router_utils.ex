defmodule NewspaperScraper.Utils.Routes.RouterUtils do
  @moduledoc """
  This module contains utilities for the Router modules
  """
  @doc """
  Transforms error tuples to maps for further encoding
  """
  @spec transform_error(error :: any()) :: map()
  def transform_error({:error, value}) when is_list(value) do
    transformed_value = for member <- value, do: Map.new([member])
    Map.new([{:error, transformed_value}])
  end

  def transform_error({:error, e}), do: Map.new([{:error, e}])

  def transform_error(value) when is_map(value), do: value

  @doc """
  Transforms query params to a map with atoms as keys
  """
  @spec transform_query_params(params :: map()) :: map()
  def transform_query_params(params) when params === %{}, do: %{}

  def transform_query_params(params) do
    for {key, val} <- params, into: %{} do
      {String.to_atom(key), val}
    end
  end
end
