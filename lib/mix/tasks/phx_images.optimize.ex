defmodule Mix.Tasks.PhxImages.Optimize do
  @shortdoc "Optimizes images by creating multiple sizes and formats"

  @moduledoc """
  Optimizes images by creating multiple sizes and formats.

  ## Usage

      mix phx_images.optimize path/to/image.jpg -o output_folder
      mix phx_images.optimize path/to/images_directory -o output_folder

  ## Options

    * `-o, --output` - Output directory (required)
    * `--sizes` - Comma-separated list of sizes (default: xs,sm,md,lg,xl,thumb)
    * `--formats` - Comma-separated list of formats (default: webp,avif,jpg)
    * `--quality` - Image quality 1-100 (default: 75)
    * `--effort` - Compression effort 1-10 (default: 10)

  ## Examples

      # Optimize a single image
      mix phx_images.optimize photo.jpg -o optimized_images

      # Optimize all images in a directory
      mix phx_images.optimize images/ -o optimized_images

      # Custom sizes and formats
      mix phx_images.optimize photo.jpg -o output --sizes sm,md,lg --formats webp,jpg

      # Custom quality settings
      mix phx_images.optimize photo.jpg -o output --quality 85 --effort 8
  """

  use Mix.Task

  @extension_whitelist ~w(.jpg .jpeg .gif .png .webp .avif)

  def run(args) do
    Application.ensure_all_started(:image)

    {opts, [input_path], _} =
      OptionParser.parse(args,
        strict: [
          output: :string,
          sizes: :string,
          formats: :string,
          quality: :integer,
          effort: :integer
        ],
        aliases: [o: :output]
      )

    output_dir = opts[:output] || Mix.raise("Output directory (-o) is required")
    sizes = parse_sizes(opts[:sizes])
    formats = parse_formats(opts[:formats])

    image_options = [
      quality: opts[:quality] || 75,
      effort: opts[:effort] || 10,
      minimize_file_size: true,
      strip_metadata: true
    ]

    if not File.exists?(input_path) do
      Mix.raise("Input path does not exist: #{input_path}")
    end

    File.mkdir_p!(output_dir)

    if File.dir?(input_path) do
      optimize_directory(input_path, output_dir, sizes, formats, image_options)
    else
      optimize_single_image(input_path, output_dir, sizes, formats, image_options)
    end

    Mix.shell().info("✅ Image optimization complete!")
  end

  defp parse_sizes(nil) do
    [:xs, :sm, :md, :lg, :xl, :thumb]
  end

  defp parse_sizes(sizes_string) do
    sizes_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp parse_formats(nil) do
    ["webp", "avif", "jpg"]
  end

  defp parse_formats(formats_string) do
    formats_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp optimize_directory(input_dir, output_dir, sizes, formats, image_options) do
    pattern = Path.join(input_dir, "**/*.{jpg,jpeg,png,gif,webp,avif}")

    file_paths = Path.wildcard(pattern, match_dot: false)

    if Enum.empty?(file_paths) do
      Mix.shell().info("No image files found in directory: #{input_dir}")
    else
      Mix.shell().info("Found #{length(file_paths)} images to optimize...")

      file_paths
      |> Enum.with_index(1)
      |> Enum.each(fn {file_path, index} ->
        Mix.shell().info("[#{index}/#{length(file_paths)}] Processing #{Path.basename(file_path)}...")
        relative_path = Path.relative_to(file_path, input_dir)
        output_subdir = Path.join(output_dir, Path.dirname(relative_path))
        optimize_single_image(file_path, output_subdir, sizes, formats, image_options)
      end)
    end
  end

  defp optimize_single_image(input_path, output_dir, sizes, formats, image_options) do
    if valid_image?(input_path) do
      File.mkdir_p!(output_dir)
      base_name = Path.basename(input_path, Path.extname(input_path))

      try do
        image = Image.open!(input_path)

        # Create all size variants for each format
        for size <- sizes, format <- formats do
          output_filename = "#{base_name}_#{size}.#{format}"
          output_path = Path.join(output_dir, output_filename)

          processed_image = process_image_for_size(image, size)

          format_options = get_options_for_format(format, image_options)

          case Image.write(processed_image, output_path, format_options) do
            {:ok, _} ->
              Mix.shell().info("  ✓ Created #{output_filename}")

            {:error, reason} ->
              Mix.shell().error("  ✗ Failed to create #{output_filename}: #{reason}")
          end
        end
      rescue
        error ->
          Mix.shell().error("Failed to process #{input_path}: #{Exception.message(error)}")
      end
    else
      Mix.shell().error("Skipping unsupported file: #{input_path}")
    end
  end

  defp valid_image?(file_path) do
    extension = file_path |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, extension)
  end

  defp process_image_for_size(image, :thumb) do
    {:ok, processed} = Image.thumbnail(image, 320)
    processed
  end

  defp process_image_for_size(image, size) when size in [:xs, :sm, :md, :lg, :xl] do
    width = get_width_for_size(size)
    {:ok, processed} = Image.thumbnail(image, width)
    processed
  end

  defp process_image_for_size(image, _), do: image

  defp get_width_for_size(:xs), do: 320
  defp get_width_for_size(:sm), do: 768
  defp get_width_for_size(:md), do: 1024
  defp get_width_for_size(:lg), do: 1280
  defp get_width_for_size(:xl), do: 1536

  defp get_options_for_format("jpg", base_options) do
    Keyword.delete(base_options, :effort)
  end

  defp get_options_for_format("jpeg", base_options) do
    Keyword.delete(base_options, :effort)
  end

  defp get_options_for_format(_format, base_options) do
    base_options
  end
end
