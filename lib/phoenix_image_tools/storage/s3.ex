defmodule PhoenixImageTools.Storage.S3 do
  @moduledoc """
  An S3 storage adapter for PhoenixImageTools.

  This module provides functionality to upload images to an S3-compatible storage service.

  ## Configuration

  ```elixir
  config :phoenix_image_tools, :storage,
    adapter: PhoenixImageTools.Storage.S3,
    bucket: "your-bucket-name",
    region: "your-region"

  # Configure ExAws
  config :ex_aws,
    access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
    secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]
  ```
  """

  alias PhoenixImageTools

  @doc """
  Uploads a complete set of image sizes to S3.

  Takes a Plug.Upload struct and generates all configured image sizes,
  uploading them to S3 with appropriate metadata.

  Returns a map with URLs for each size, including a "default" and "thumbnail" URL.

  ## Examples

      iex> MyApp.Storage.S3.upload_to_complete_set(upload)
      %{
        "320" => "https://bucket.s3.amazonaws.com/articles/xs_uuid.webp",
        "768" => "https://bucket.s3.amazonaws.com/articles/sm_uuid.webp",
        "1024" => "https://bucket.s3.amazonaws.com/articles/md_uuid.webp",
        "1280" => "https://bucket.s3.amazonaws.com/articles/lg_uuid.webp",
        "1536" => "https://bucket.s3.amazonaws.com/articles/xl_uuid.webp",
        "default" => "https://bucket.s3.amazonaws.com/articles/xl_uuid.webp",
        "thumbnail" => "https://bucket.s3.amazonaws.com/articles/xs_uuid.webp"
      }
  """
  def upload_to_complete_set(%Plug.Upload{} = image_upload, prefix \\ "articles") do
    file_path = image_upload.path

    uuid = Ecto.UUID.generate()

    files =
      Enum.map(PhoenixImageTools.image_sizes(), fn {size, width} ->
        file_name = "#{size}_#{uuid}.#{PhoenixImageTools.output_extension()}"

        {:ok, url} =
          file_path
          |> Image.open!()
          |> Image.thumbnail!(width, PhoenixImageTools.thumbnail_options())
          |> Image.stream!(PhoenixImageTools.stream_image_options())
          |> ExAws.S3.upload(
            PhoenixImageTools.bucket_name(),
            "#{prefix}/#{file_name}",
            content_type: "image/#{PhoenixImageTools.output_extension()}",
            cache_control: "public, max-age=#{PhoenixImageTools.max_age()}"
          )
          |> ExAws.request()
          |> build_url()

        {width, url}
      end)

    data =
      Enum.reduce(files, %{}, fn {width, url}, acc ->
        Map.put(acc, "#{width}", url)
      end)

    # Choose the largest size as default and the smallest as thumbnail
    {_, largest_size} = Enum.max_by(PhoenixImageTools.image_sizes(), fn {_, width} -> width end)
    {_, smallest_size} = Enum.min_by(PhoenixImageTools.image_sizes(), fn {_, width} -> width end)

    data
    |> Map.put("default", Map.fetch!(data, "#{largest_size}"))
    |> Map.put("thumbnail", Map.fetch!(data, "#{smallest_size}"))
  end

  @doc """
  Builds a URL for an S3 object.
  """
  def build_url({:ok, %{body: %{key: location}}}) do
    :s3
    |> ExAws.Config.new([])
    |> build_url(PhoenixImageTools.bucket_name(), location)
  end

  def build_url(config, bucket, object) do
    port = ""

    {:ok, "#{config[:scheme]}#{config[:host]}#{port}/#{bucket}/#{object}"}
  end
end
