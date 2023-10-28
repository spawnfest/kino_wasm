defmodule KinoWasm.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_wasm,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KinoWasm, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.11.0"},
      {:wasm_runner, path: "../wasm_runner"}
    ]
  end
end
