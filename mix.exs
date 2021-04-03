defmodule Transaction.MixProject do
  use Mix.Project

  def project do
    [
      app: :transactions,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
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
      {:typed_struct, "~> 0.2.1"},
      {:credo, "~> 1.5", only: [:dev]},
      {:dialyxir, "~> 1.1", only: [:dev]}
    ]
  end
end
