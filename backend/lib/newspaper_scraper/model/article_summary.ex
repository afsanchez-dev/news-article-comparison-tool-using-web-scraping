defmodule NewspaperScraper.Model.ArticleSummary do
  @moduledoc """
  This module defines the struct for article summaries
  """

  alias NewspaperScraper.Model.Author

  @type t :: %__MODULE__{
          newspaper: String.t(),
          authors: list(Author.t()),
          title: String.t(),
          excerpt: String.t(),
          date_time: String.t(),
          url: String.t(),
          is_premium: boolean()
        }

  @art_sum_keys [
    :newspaper,
    :authors,
    :title,
    :excerpt,
    :date_time,
    :url,
    :is_premium
  ]

  @derive {Jason.Encoder, only: @art_sum_keys}
  @enforce_keys @art_sum_keys
  defstruct @art_sum_keys
end
