defmodule NewspaperScraper.Boundary.Validator do
  @moduledoc """
  This module implements generic validation functions
  """

  @doc """
  Checks if mandatory fields are valid
  """
  @spec mandatory(errors :: list(), fields :: map(), field_name :: atom(), validator :: fun()) :: list() | {:error, any()}
  def mandatory(errors, fields, field_name, validator) do
    is_present = Map.has_key?(fields, field_name)
    check_mandatory_field(is_present, fields, errors, field_name, validator)
  end

  # Applies the check function to the field value
  @spec check_mandatory_field(boolean(), fields :: map(), errors :: list(), field_name :: atom(), check_fun :: fun()) :: list() | {:error, any()}
  defp check_mandatory_field(true, fields, errors, field_name, check_fun) do
    try do
      fields
      |> Map.fetch!(field_name)
      |> check_fun.()
      |> check_field(errors, field_name)
    rescue
      e -> {:error, e}
    end
  end

  defp check_mandatory_field(false, _fields, errors, field_name, _check_fun) do
    errors ++ [{field_name, "is mandatory"}]
  end

  # Appends new errors in case there are any
  @spec check_field(atom() | {:error, any()}, errors:: list(), field_name :: atom()) :: list()
  defp check_field(:ok, errors, _field_name), do: errors

  defp check_field({:error, message}, errors, field_name) do
    errors ++ [{field_name, message}]
  end

  @doc """
  Checks if optional fields are valid
  """
  @spec optional(errors :: list(), fields :: map(), field_name :: atom(), validator :: fun()) :: list() | {:error, any()}
  def optional(errors, fields, field_name, validator) do
    case Map.has_key?(fields, field_name) do
      true -> mandatory(errors, fields, field_name, validator)
      false -> errors
    end
  end

  @doc """
  If a validation condition is false returns a custom message
  """
  @spec check(condition :: boolean(), message :: any()) :: :ok | any()
  def check(true, _message), do: :ok
  def check(false, message), do: message

  @doc """
  Checks validation errors exist
  """
  @spec has_errors(errors :: list()) :: :ok | {:error, list()}
  def has_errors([]), do: :ok
  def has_errors(errors), do: {:error, errors}
end
