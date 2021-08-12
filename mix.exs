defmodule Money.Mixfile do
  use Mix.Project

  @vsn "0.3.3"

  def project do
    [
      app: :ih_money,
      name: "Money",
      version: @vsn,
      package: package(),
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp package do
    [
      description: "Money amount converter",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/heathmont/money-elixir"
      }
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
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:poison, "~> 5.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
