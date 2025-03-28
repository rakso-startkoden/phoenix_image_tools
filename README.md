# PhoenixImageTools

A toolkit for efficient image handling in Phoenix applications.

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_image_tools.svg)](https://hex.pm/packages/phoenix_image_tools)
[![Hex.pm](https://img.shields.io/hexpm/dt/phoenix_image_tools.svg)](https://hex.pm/packages/phoenix_image_tools)
[![Hex.pm](https://img.shields.io/hexpm/l/phoenix_image_tools.svg)](https://hex.pm/packages/phoenix_image_tools)

PhoenixImageTools is a library that simplifies image handling in Phoenix applications by providing tools for uploading, processing, and displaying responsive images. It handles automatic resizing, format conversion, and optimized delivery through HTML picture elements with srcset attributes.

## Features

- 🖼️ **Responsive Images**: Generate multiple image sizes for responsive web design
- 🚀 **Optimized Format**: Convert images to WebP for better performance
- 📦 **S3 Integration**: Easy upload to S3 with proper headers and caching
- 🧩 **LiveView Components**: Ready-to-use Phoenix LiveView components for image display
- 📱 **Responsive Display**: Built-in support for srcset and picture element
- 🔍 **Zoom Support**: Optional image zoom functionality
- 🔄 **Ecto Integration**: Seamless integration with your Ecto schemas

## Installation

Add `phoenix_image_tools` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_image_tools, "~> 0.1.0"}
  ]
end
```

## Configuration

### Basic Configuration

```elixir
# In your config/config.exs
config :phoenix_image_tools,
  output_format: "webp",
  max_age: 31_536_000, # 1 year
  image_sizes: [
    xs: 320,
    sm: 768,
    md: 1024,
    lg: 1280,
    xl: 1536
  ]
```

### S3 Configuration

PhoenixImageTools uses ExAws for S3 integration:

```elixir
config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION")

config :phoenix_image_tools,
  bucket: "your-bucket-name",
  storage_dir: "images"
```

## Usage

### Image Uploader

Define your uploader module:

```elixir
defmodule MyApp.MediaUploader do
  use PhoenixImageTools.Uploader

  # Optional: Override storage directory
  def storage_dir(_, {_file, _scope}) do
    "uploads/custom_path"
  end
end
```

### Schema Integration

Use the uploader in your Ecto schema:

```elixir
defmodule MyApp.Media do
  use Ecto.Schema
  use PhoenixImageTools.Schema

  schema "media" do
    field :image, MyApp.MediaUploader.Type
    timestamps()
  end

  def changeset(media, attrs) do
    media
    |> cast(attrs, [:image])
    |> cast_attachments(attrs, [:image])
    |> validate_required([:image])
  end
end
```

### Controller Example

Upload an image in your controller:

```elixir
def create(conn, %{"media" => media_params}) do
  case Media.create_media(media_params) do
    {:ok, media} ->
      # Successfully uploaded and processed
      redirect(to: Routes.media_path(conn, :show, media))
    {:error, changeset} ->
      # Handle error
      render(conn, "new.html", changeset: changeset)
  end
end
```

### LiveView Component

Display responsive images in your templates:

```heex
<.live_component
  module={PhoenixImageTools.Components.Picture}
  id={"media-#{@media.id}"}
  url_fun={fn version -> MyApp.MediaUploader.url({@media.image, @media}, version) end}
  versions={[:xs, :sm, :md, :lg, :xl]}
  base={:original}
  lazy_loading={true}
  rounded={true}
  zoomable={true}
  alt="Image description"
/>
```

## Advanced Configuration

### Image Processing Options

Configure image processing options:

```elixir
config :phoenix_image_tools,
  thumbnail_options: [],
  stream_image_options: [
    suffix: ".webp",
    buffer_size: 5_242_880,
    minimize_file_size: true,
    quality: 75,
    effort: 10
  ],
  write_image_options: [
    minimize_file_size: true,
    quality: 75,
    effort: 10
  ]
```

## Example: Direct Upload

Process and upload an image directly:

```elixir
def upload_image(%Plug.Upload{} = image_upload) do
  PhoenixImageTools.upload_image(image_upload)
end
```

## Dependencies

PhoenixImageTools relies on the following libraries:

- [Waffle](https://github.com/elixir-waffle/waffle) - For file uploads
- [Image](https://github.com/elixir-image/image) - For image processing
- [ExAws](https://github.com/ex-aws/ex_aws) - For S3 integration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
