defmodule Sheetex.MixProject do
  use Mix.Project

  def project do
    [
      app: :sheetex,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34.1", only: :dev, runtime: false},
      {:dotenvy, "~> 0.8.0", only: [:test]},
      {:google_api_sheets, "0.31.0"}
    ]
  end
end
