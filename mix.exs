defmodule Sheetex.MixProject do
  use Mix.Project

  def project do
    [
      app: :sheetex,
      version: "0.1.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Sheetex",
      description: description(),
      package: package(),
      source_url: "https://github.com/malinowskip/sheetex",
      homepage_url: "https://github.com/malinowskip/sheetex",
      docs: docs()
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
      {:google_api_sheets, "0.31.0"},
      {:ex_doc, "~> 0.34.1", only: :dev, runtime: false},
      {:dotenvy, "~> 0.8.0", only: [:test]}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/malinowskip/sheetex"}
    ]
  end

  defp description do
    "Fetch rows from a Google Sheet."
  end

  defp docs do
    [
      main: "Sheetex"
    ]
  end
end
