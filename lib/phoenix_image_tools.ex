defmodule PhoenixImageTools do
  @moduledoc """
  PhoenixImageTools is a comprehensive solution for handling responsive images
  in Phoenix applications.

  This library provides tools for:
  - Uploading and processing images
  - Creating multiple image sizes for responsive web applications
  - Converting images to optimized formats (WebP)
  - Providing Phoenix LiveView components for responsive image display
  - Supporting S3-compatible storage
  """

  @doc """
  Returns the configured image sizes.

  ## Examples

      iex> PhoenixImageTools.image_sizes()
      [xs: 320, sm: 768, md: 1024, lg: 1280, xl: 1536]
  """
  def image_sizes do
    Application.get_env(:phoenix_image_tools, :image_sizes, [
      {:xs, 320},
      {:sm, 768},
      {:md, 1024},
      {:lg, 1280},
      {:xl, 1536}
    ])
  end

  @doc """
  Returns the width for a given size name.

  ## Examples

      iex> PhoenixImageTools.get_width_from_size(:md)
      1024
  """
  def get_width_from_size(size) do
    Keyword.fetch!(image_sizes(), size)
  end

  @doc """
  Returns the configured output extension for processed images.

  ## Examples

      iex> PhoenixImageTools.output_extension()
      "webp"
  """
  def output_extension do
    Application.get_env(:phoenix_image_tools, :output_extension, "webp")
  end

  @doc """
  Returns the configured cache control max-age value in seconds.

  ## Examples

      iex> PhoenixImageTools.max_age()
      31536000
  """
  def max_age do
    Application.get_env(:phoenix_image_tools, :max_age, 31_536_000)
  end

  @doc """
  Returns the configured thumbnail options for image processing.
  """
  def thumbnail_options do
    Application.get_env(:phoenix_image_tools, :thumbnail_options, [])
  end

  @doc """
  Returns the configured streaming options for image processing.
  """
  def stream_image_options do
    Application.get_env(:phoenix_image_tools, :stream_image_options,
      suffix: ".#{output_extension()}",
      buffer_size: 5_242_880,
      minimize_file_size: true,
      quality: 75,
      effort: 10
    )
  end

  @doc """
  Returns the configured write options for image processing.
  """
  def write_image_options do
    Application.get_env(:phoenix_image_tools, :write_image_options,
      minimize_file_size: true,
      quality: 75,
      effort: 10
    )
  end

  @doc """
  Returns the configured bucket name for S3 storage.
  """
  def bucket_name do
    get_in(Application.get_env(:phoenix_image_tools, :storage, []), [:bucket]) ||
      raise "No bucket name configured for PhoenixImageTools"
  end

  @doc """
  Returns the configured write options for image processing.
  """
  def asset_host do
    get_in(Application.get_env(:phoenix_image_tools, :storage, []), [:asset_host])
  end
end
