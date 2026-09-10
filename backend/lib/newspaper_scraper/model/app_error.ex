defmodule NewspaperScraper.Model.AppError do
  @moduledoc """
  This module defines the struct for an app error
  """

  @type t :: %__MODULE__{
          error: String.t()
        }

  @app_error_keys [
    :error
  ]

  @derive {Jason.Encoder, only: @app_error_keys}
  @enforce_keys @app_error_keys
  defstruct @app_error_keys
end
