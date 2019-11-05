defmodule JsonConfix.MixProject do
  use Mix.Project

  @project_url "https://github.com/quri/json_confix"
  @version "0.2.0"

  def project do
    [
      app: :json_confix,
      name: "JsonConfix",
      version: @version,
      elixir: "~> 1.6 or ~> 1.9",
      package: package(),
      description: description(),
      start_permanent: Enum.member?([:prod, :int], Mix.env()),
      docs: docs(),

      deps: deps()
    ]
  end


  defp package do
    [
      maintainers: ["Trax Retail"],
      licenses: ["Beerware"],
      links: %{
        "GitHub" => @project_url,
        "ConfigTuples" => "https://github.com/rockneurotiko/config_tuples"
      }
    ]
  end

  defp description do
    "JsonConfix is a Elixir config provider for Distillery that replaces config tuples (e.g `{:json, value}`) \
    to the correspondent value read from a JSON file."
  end

  def docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/quri/json_confix"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0", runtime: false},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.21", only: :dev}
    ]
  end
end
