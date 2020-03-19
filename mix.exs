defmodule Money.Mixfile do
  use Mix.Project

  @vsn "0.3.0"

  def project do
    [
      app: :ih_money,
      name: "Money",
      description: "Money amount converter",
      source_url: "https://github.com/heathmont/money-elixir",
      version: @vsn,
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger
      ]
    ]
  end

  defp deps do
    [
      {:poison, "~> 4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
