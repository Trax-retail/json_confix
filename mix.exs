defmodule JsonConfix.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_confix,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Enum.member?([:prod, :int], Mix.env()),
      deps: deps()
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
