defmodule PhoenixImageTools.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/yourusername/phoenix_image_tools"

  def project do
    [
      app: :phoenix_image_tools,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.19.0"},
      {:phoenix_html, "~> 3.3"},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.11"},
      {:image, "~> 0.37.0"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.7.3"},
      {:jason, "~> 1.4"},

      # Dev and test deps
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    A comprehensive solution for handling responsive images in Phoenix applications.
    Features include image uploading, processing, responsive components, and S3 storage support.
    """
  end

  defp package do
    [
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get"],
      lint: ["format", "credo --strict"],
      test: ["lint", "test"]
    ]
  end
end
