defmodule PhoenixImageTools.Components do
  @moduledoc """
  Provides Phoenix LiveView components for displaying responsive images.

  ## Usage

  ```heex
  <.picture
    versions={[:xs, :sm, :md, :lg, :xl]}
    base={:original}
    url_fun={&MyApp.Uploaders.ProfileImageUploader.url({@user.profile_image, @user}, &1)}
    alt="User profile image"
    lazy_loading={true}
    rounded={true}
    class="object-cover"
  />
  ```
  """

  use Phoenix.Component

  alias PhoenixImageTools

  @doc """
  Renders a responsive picture element with proper srcset attributes.

  ## Attributes

  * `class` - CSS classes to apply to the picture element.
  * `url_fun` - Function to generate URLs for different image versions.
  * `versions` - List of image versions to include in the srcset.
  * `base` - Base version to use as the default image src.
  * `zoom_version` - Version to use for the zoomable view (defaults to base if not provided).
  * `lazy_loading` - Whether to enable lazy loading for the image.
  * `rounded` - Whether to apply rounded corners to the image.
  * `zoomable` - Whether the image should be zoomable.
  * `alt` - Alternative text for the image.
  * `height` - Height attribute for the image (defaults to 500).
  * `width` - Width attribute for the image (defaults to 500).
  """
  attr(:class, :any,
    default: nil,
    doc: "CSS classes to apply to the picture element."
  )

  attr(:url_fun, :any, doc: "Function to generate URLs for different image versions.")

  attr(:versions, :list, doc: "List of image versions to include in the srcset.")

  attr(:base, :atom, doc: "Base version to use as the default image src.")

  attr(:zoom_version, :atom,
    doc: "Version to use for the zoomable view (defaults to base if not provided).",
    default: nil
  )

  attr(:lazy_loading, :boolean,
    doc: "Whether to enable lazy loading for the image.",
    default: false
  )

  attr(:rounded, :boolean,
    doc: "Whether to apply rounded corners to the image.",
    default: false
  )

  attr(:zoomable, :boolean,
    doc: "Whether the image should be zoomable.",
    default: false
  )

  attr(:alt, :string,
    default: "",
    doc: "Alternative text for the image."
  )

  attr(:height, :integer,
    default: 500,
    doc: "Height attribute for the image."
  )

  attr(:width, :integer,
    default: 500,
    doc: "Width attribute for the image."
  )

  attr(:rest, :global)

  def picture(assigns) do
    assigns =
      assigns
      |> assign_versions()
      |> assign_original()
      |> assign_zoom_version_url()

    ~H"""
    <picture class={[@class]} {@rest}>
      <%= for version <- @_versions do %>
        <source media={"(max-width: #{version.width}px)"} srcset={version.url} />
      <% end %>
      <img
        src={@original.url}
        alt={@alt}
        loading={
          if @lazy_loading do
            "lazy"
          end
        }
        width={@width}
        height={@height}
        data-zoom-src={@zoom_version_url}
        data-zoomable={@zoomable}
        class={[@rounded && "rounded-2xl", @class]}
      />
    </picture>
    """
  end

  defp assign_versions(assigns) do
    versions =
      Enum.map(assigns.versions, fn version ->
        %{
          url: assigns.url_fun.(version),
          width: PhoenixImageTools.get_width_from_size(version)
        }
      end)

    assign(assigns, :_versions, versions)
  end

  defp assign_original(assigns) do
    original = %{
      url: assigns.url_fun.(assigns.base)
    }

    assign(assigns, :original, original)
  end

  defp assign_zoom_version_url(assigns) do
    zoom_version_url =
      if assigns.zoom_version do
        assigns.url_fun.(assigns.zoom_version)
      else
        assigns.original.url
      end

    assign(assigns, :zoom_version_url, zoom_version_url)
  end
end
