defmodule Money.Mixfile do
  use Mix.Project

  @version (case File.read("VERSION") do
    {:ok, version} -> String.trim(version)
    {:error, _} -> "0.0.0-development"
  end)

  def project do
    [
      app: :ih_money,
      name: "Money",
      version: @version,
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      # docs
      name: "Money",
      source_url: "https://github.com/coingaming/money-elixir",
      homepage_url: "https://github.com/coingaming/money-elixir/tree/v#{@version}",
      docs: [
        source_ref: "v#{@version}"
      ]
    ]
  end

  def application do
    [
      extra_applications: [
        :logger
      ]
    ]
  end

  defp package do
    [
      organization: "coingaming",
      description: "Money amount converter",
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "VERSION", "priv/currency-config/config.json"],
      links: %{
        "GitHub" => "https://github.com/coingaming/money-elixir/tree/v#{@version}"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: [:test, :dev], runtime: false},
      {:poison, "~> 4.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
