defmodule NewspaperScraper.Model.Article do
  @moduledoc """
  This module defines the struct for articles
  """

  alias NewspaperScraper.Model.Author

  @type t :: %__MODULE__{
          newspaper: String.t(),
          headline: String.t(),
          subheadline: String.t(),
          authors: list(Author.t()),
          last_date_time: String.t(),
          body: list(),
          url: String.t()
        }

  @art_keys [
    :newspaper,
    :headline,
    :subheadline,
    :authors,
    :last_date_time,
    :body,
    :url
  ]

  @derive {Jason.Encoder, only: @art_keys}
  @enforce_keys @art_keys
  defstruct @art_keys
end
