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

      import Ecto.Changeset

      @doc """
      A changeset helper that handles attachment fields and supports the "delete" virtual field
      pattern for removing existing uploads.
      """
      def cast_attachments(changeset, attrs, fields, opts \\ []) do
        changeset = Waffle.Ecto.Schema.cast_attachments(changeset, attrs, fields, opts)

        Enum.reduce(fields, changeset, fn field, acc ->
          delete_field = String.to_existing_atom("#{field}_delete")

          case get_change(acc, field) do
            nil ->
              if get_field(acc, delete_field) do
                put_change(acc, field, nil)
              else
                acc
              end

            _file ->
              acc
          end
        end)
      end

      @doc """
      Helper to mark an attachment for deletion based on a virtual "delete" field.
      """
      def maybe_mark_for_deletion(changeset) do
        if get_change(changeset, :delete) do
          %{changeset | action: :delete}
        else
          changeset
        end
      end
    end
  end
end
