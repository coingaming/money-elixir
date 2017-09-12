defmodule Mix.Tasks.Gen.Currency.Config do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Update the currency config file."

  @moduledoc """
  Converts `priv/currency-config/config.json`
  to `currency_config.exs` in the `config` subdir.
  """

  @doc false
  def run(_args) do
    create_file Path.join("config", "currency_config.exs"), currency_config_template([
      json: Application.app_dir(:money, "priv/currency-config/config.json")
            |> File.read!
            |> Poison.decode!(keys: :atoms)
    ])
  end

  embed_template :currency_config, """
  # Generated with `mix gen.currency.config`
  use Mix.Config
  config :money,
    currency_config:
    <%= inspect @json, pretty: true, width: 16 %>
  """
end
