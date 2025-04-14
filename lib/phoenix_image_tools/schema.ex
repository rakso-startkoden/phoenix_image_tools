defmodule PhoenixImageTools.Schema do
  @moduledoc """
  Provides conveniences for schemas working with image uploads.

  This module simplifies the integration of image uploads with Ecto schemas.

  ## Usage

  ```elixir
  defmodule MyApp.Accounts.User do
    use Ecto.Schema
    use PhoenixImageTools.Schema

    schema "users" do
      field :name, :string
      field :profile_image, MyApp.Uploaders.ProfileImageUploader.Type
      
      timestamps()
    end

    def changeset(user, attrs) do
      user
      |> cast(attrs, [:name])
      |> cast_attachments(attrs, [:profile_image], allow_paths: true)
      |> validate_required([:name, :profile_image])
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use Waffle.Ecto.Schema
    end
  end
end
