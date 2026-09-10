defmodule NewspaperScraper.Model.Author do
  @moduledoc """
  This module defines the struct for authors
  """

  @type t :: %__MODULE__{
          name: String.t(),
          url: String.t()
        }

  @author_keys [
    :name,
    :url
  ]

  @derive {Jason.Encoder, only: @author_keys}
  @enforce_keys [:name]
  defstruct @author_keys
end
