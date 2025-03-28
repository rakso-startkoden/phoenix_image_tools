defmodule PhoenixImageTools.Uploader do
  @moduledoc """
  Provides a macro to define image uploaders with built-in support for
  multiple image sizes and format conversion.

  ## Usage

  ```elixir
  defmodule MyApp.Uploaders.ProfileImageUploader do
    use PhoenixImageTools.Uploader

    @extension_whitelist ~w(.jpg .jpeg .gif .png .webp)

    def validate({file, _}) do
      file_extension = file.file_name |> Path.extname() |> String.downcase()
      Enum.member?(@extension_whitelist, file_extension)
    end

    def storage_dir(_, {_file, _scope}) do
      "uploads/profile_images"
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use Waffle.Definition
      use Waffle.Ecto.Definition

      alias PhoenixImageTools

      # Define versions based on the configured image sizes
      @versions ([:original, :thumbnail] ++ Keyword.keys(PhoenixImageTools.image_sizes()))
                |> Enum.uniq()
                |> List.to_tuple()

      def filename(version, {file, _scope}) do
        file_name = Path.basename(file.file_name)
        file_name = String.replace(file_name, Path.extname(file_name), "")
        "#{version}_#{file_name}"
      end

      def transform(:original, _) do
        {&process/2, fn _, _ -> String.to_atom(PhoenixImageTools.output_extension()) end}
      end

      def transform(_version, _file) do
        {&process/2, fn _, _ -> String.to_atom(PhoenixImageTools.output_extension()) end}
      end

      def s3_object_headers(_version, {file, _scope}) do
        [
          content_type: MIME.from_path(file.file_name),
          cache_control: "public, max-age=#{PhoenixImageTools.max_age()}"
        ]
      end

      @spec process(
              atom(),
              Waffle.File.t()
            ) :: {:ok, Waffle.File.t()} | {:error, String.t()}
      def process(:original, file) do
        new_path = Waffle.File.generate_temporary_path(PhoenixImageTools.output_extension())

        image = Image.open!(file.path)

        case Image.write(image, new_path, PhoenixImageTools.write_image_options()) do
          {:ok, _image} ->
            new_file = %{
              file
              | path: new_path,
                is_tempfile?: true
            }

            {:ok, new_file}
        end
      end

      def process(:thumbnail, file) do
        new_path = Waffle.File.generate_temporary_path(PhoenixImageTools.output_extension())

        {:ok, image} =
          file.path
          |> Image.open!()
          |> Image.thumbnail(320, PhoenixImageTools.thumbnail_options())

        case Image.write(image, new_path, PhoenixImageTools.write_image_options()) do
          {:ok, _image} ->
            new_file = %{
              file
              | path: new_path,
                is_tempfile?: true
            }

            {:ok, new_file}
        end
      end

      def process(size, file) do
        width = PhoenixImageTools.get_width_from_size(size)

        new_path = Waffle.File.generate_temporary_path(PhoenixImageTools.output_extension())

        {:ok, image} =
          file.path
          |> Image.open!()
          |> Image.thumbnail(width, PhoenixImageTools.thumbnail_options())

        case Image.write(image, new_path, PhoenixImageTools.write_image_options()) do
          {:ok, _image} ->
            new_file = %{
              file
              | path: new_path,
                is_tempfile?: true
            }

            {:ok, new_file}
        end
      end

      defoverridable storage_dir: 2,
                     validate: 1,
                     filename: 2
    end
  end
end
