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

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

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

  @doc """
  """
  attr(:title, :string, default: nil)

  slot(:inner_block, required: true)

  def nested_form_box(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-300 bg-gray-50 p-4">
      <h3 :if={@title} class="font-cormorant mb-4 text-xl font-semibold text-rose-700">{@title}</h3>
      <div class="space-y-8">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a file upload field component for handling image uploads with preview.

  This component simplifies the creation of LiveView file upload experiences,
  supporting both new uploads and displaying previously uploaded images.

  ## Examples

  ```heex
  <.form_upload_field
    upload={@uploads}
    name={:images}
    label="Product Images"
  />
  ```

  With previous uploads and custom cancel action:

  ```heex
  <.form_upload_field
    upload={@uploads}
    name={:profile_image}
    label="Profile Picture"
    target={@myself}
    accept={~w(.jpg .jpeg .png)}
    max_entries={1}
  >
    <:previous_uploads>
      <.inputs_for :let={image_form} field={@form[:images]}>
        <.hidden_input form={image_form} field={:delete} />
        <.hidden_input form={image_form} field={:id} />
        
        <div id={"image-{image_form.index}"} class={image_form[:delete].value == "true" && "hidden"}>
          <figure class="mb-2">
            <img
              src={MyApp.MediaUploader.url(Ecto.Changeset.get_field(image_form.source, :file), :thumbnail)}
              class="rounded-lg max-w-[200px]"
              alt="Uploaded image"
            />
          </figure>
          <div>
            <button
              type="button"
              phx-click="mark-image-for-deletion"
              phx-value-index={image_form.index}
              class="text-red-600 text-sm"
            >
              Remove
            </button>
          </div>
        </div>
      </.inputs_for>
    </:previous_uploads>
  </.form_upload_field>
  ```

  In the LiveView module, you'll need to set up uploads:

  ```elixir
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_form(...)
      |> allow_upload(:images, 
          accept: ~w(.jpg .jpeg .png .webp), 
          max_entries: 5, 
          max_file_size: 10_000_000
        )
      
    {:ok, socket}
  end

  def handle_event("save", %{"entity" => entity_params}, socket) do
    entity_params =
      PhoenixImageTools.Components.consume_uploads(
        socket, 
        entity_params, 
        :images, 
        generate_names: true
      )
      
    # Continue with saving logic
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end
  ```

  ## Attributes

  * `upload` - The LiveView uploads map.
  * `name` - The upload field name (must match the field name in allow_upload).
  * `label` - Optional label text for the upload field (defaults to capitalized name).
  * `target` - Optional target for phx events (useful in LiveComponents).
  * `class` - Optional CSS classes to apply to the container.
  * `drop_prompt` - Optional custom prompt for drag and drop area.
  * `accept` - Optional list of allowed file extensions (for information only).
  * `max_entries` - Optional maximum number of files (for information only).
  * `max_file_size_mb` - Optional max file size in MB (for information only).

  ## Slots

  * `previous_uploads` - Slot for rendering previously uploaded files.
  * `upload_entry` - Slot for customizing the display of upload entries.

  ## Usage with consume_uploads

  The companion function `consume_uploads/4` helps process uploaded files and prepare
  them for insertion into database records. See its documentation for details.
  """
  attr(:upload, :map, required: true, doc: "The LiveView uploads map")

  attr(:name, :atom,
    required: true,
    doc: "The upload field name (must match the field name in allow_upload)"
  )

  attr(:label, :string, default: nil, doc: "Optional label text for the upload field")

  attr(:target, :any,
    default: nil,
    doc: "Optional target for phx events (useful in LiveComponents)"
  )

  attr(:class, :string, default: "", doc: "Optional CSS classes to apply to the container")

  attr(:drop_prompt, :string,
    default: "Drag and drop files or click to browse",
    doc: "Custom prompt for drag and drop area"
  )

  attr(:accept, :list,
    default: nil,
    doc: "Optional list of allowed file extensions (for information only)"
  )

  attr(:max_entries, :integer,
    default: nil,
    doc: "Optional maximum number of files (for information only)"
  )

  attr(:max_file_size_mb, :integer,
    default: nil,
    doc: "Optional max file size in MB (for information only)"
  )

  slot(:previous_uploads, doc: "Slot for rendering previously uploaded files")

  slot(:upload_entry, doc: "Slot for customizing the display of upload entries") do
    attr(:entry, :map)
  end

  def form_upload_field(assigns) do
    assigns =
      assign_new(assigns, :label, fn %{name: name} -> String.capitalize("#{name}") end)

    ~H"""
    <div class={["image-upload-field", @class]}>
      <div class="mb-2">
        <span class="font-semibold"><%= @label %></span>
        
        <%= if @accept || @max_entries || @max_file_size_mb do %>
          <div class="mt-1 text-sm text-gray-600">
            <%= if @accept do %>
              <span>Allowed formats: <%= Enum.join(@accept, ", ") %></span>
            <% end %>
            <%= if @max_entries do %>
              <span><%= if @accept do %> · <% end %>Max files: <%= @max_entries %></span>
            <% end %>
            <%= if @max_file_size_mb do %>
              <span><%= if @accept || @max_entries do %> · <% end %>Max size: <%= @max_file_size_mb %>MB</span>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 p-4">
        <div class="mb-4 text-center">
          <p><%= @drop_prompt %></p>
          <div class="mt-2">
            <.live_file_input upload={@upload[@name]} class="sr-only" />
            <button type="button" class="rounded-md border border-gray-300 bg-gray-100 px-4 py-2 text-sm" phx-click={JS.dispatch("click", to: "##{@upload[@name].ref}")}>
              Browse files
            </button>
          </div>
        </div>

        <!-- Previous Uploads Section -->
        <%= if not Enum.empty?(@previous_uploads) do %>
          <div class="mb-4 grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
            <%= render_slot(@previous_uploads) %>
          </div>
        <% end %>

        <!-- Current Uploads Section -->
        <%= if not Enum.empty?(@upload[@name].entries) do %>
          <div class="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2 lg:grid-cols-3">
            <%= for entry <- @upload[@name].entries do %>
              <div class="upload-entry rounded-lg border bg-white p-2">
                <div class="aspect-w-1 aspect-h-1 mb-2 overflow-hidden rounded-md bg-gray-100">
                  <.live_img_preview entry={entry} class="h-full w-full object-cover" />
                </div>
                
                <div class="mt-2 space-y-2">
                  <div class="flex items-center justify-between">
                    <p class="truncate text-sm text-gray-700" title={entry.client_name}>
                      <%= entry.client_name %>
                    </p>
                    <button 
                      type="button"
                      class="text-sm text-red-600 hover:text-red-800"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      phx-target={@target}
                      aria-label="cancel"
                    >
                      Remove
                    </button>
                  </div>
                  
                  <!-- Progress bar -->
                  <div class="h-2 w-full rounded-full bg-gray-200">
                    <div class="h-2 rounded-full bg-blue-600" style={"width: #{entry.progress}%"}></div>
                  </div>
                  <p class="text-right text-xs text-gray-500"><%= entry.progress %>%</p>
                  
                  <!-- Errors -->
                  <%= for err <- upload_errors(@upload[@name], entry) do %>
                    <p class="text-sm text-red-500"><%= format_error(err) %></p>
                  <% end %>
                  
                  <!-- Custom slot -->
                  <%= if not Enum.empty?(@upload_entry) do %>
                    <%= render_slot(@upload_entry, entry) %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_error(:too_large), do: "File is too large"
  defp format_error(:too_many_files), do: "Too many files"
  defp format_error(:not_accepted), do: "Unacceptable file type"
  defp format_error(err), do: to_string(err)

  @doc """
  Processes uploaded files and prepares them for insertion into database records.

  This function helps consume LiveView uploads and merge the results into the 
  params map, making it ready for changesets. It's designed to work with the
  `form_upload_field` component and handles both single and multiple file uploads.

  ## Parameters

  * `socket` - The LiveView socket with uploads
  * `params` - The params map (usually from the form submission)
  * `field_key` - The atom key of the upload field
  * `options` - A keyword list of options
    * `:generate_names` - When true, generates unique UUIDs for filenames (default: false)

  ## Returns

  The updated params map with the uploaded files merged in.

  ## Examples

  ```elixir
  # In a LiveView handle_event function
  def handle_event("save", %{"product" => product_params}, socket) do
    product_params =
      PhoenixImageTools.Components.consume_uploads(
        socket, 
        product_params, 
        :images, 
        generate_names: true
      )
    
    case Products.create_product(product_params) do
      {:ok, product} ->
        {:noreply, socket |> put_flash(:info, "Product created") |> push_navigate(to: ~p"/products")}
      
      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
  ```

  The files will be available in your changeset as a list of maps in the format:

  ```elixir
  %{
    "0" => %{"delete" => "false", "file" => "/path/to/file.jpg"},
    "1" => %{"delete" => "false", "file" => "/path/to/another_file.png"}
  }
  ```

  This format is compatible with `cast_attachments/4` from `PhoenixImageTools.Schema`.
  """
  @spec consume_uploads(Socket.t(), map(), atom(), keyword()) :: map()
  def consume_uploads(socket, params, field_key, options \\ [])
      when is_atom(field_key) and is_map(params) do
    defaults = [
      generate_names: false,
      extension: "image"
    ]

    options = options |> Keyword.validate!(defaults) |> Map.new()

    # Get existing upload params from the form submission
    upload_params = Map.get(params, "#{field_key}", %{})

    case Phoenix.LiveView.consume_uploaded_entries(socket, field_key, fn %{path: path}, entry ->
           # Add the file extension to the temp file
           path_with_extension =
             path <> String.replace(entry.client_type, "#{options.extension}/", ".")

           # Generate unique filenames if requested
           path_with_extension =
             if options.generate_names do
               dir_name = Path.dirname(path_with_extension)
               file_name = "#{Ecto.UUID.generate()}#{Path.extname(path_with_extension)}"
               Path.join([dir_name, file_name])
             else
               path_with_extension
             end

           # Create a copy with the correct extension
           File.cp!(path, path_with_extension)

           # Return the file info in the format expected by cast_attachments
           {:ok,
            %{
              "delete" => "false",
              "file" => path_with_extension
            }}
         end) do
      [] ->
        # No new files uploaded, return params unchanged
        params

      uploaded_files when is_list(uploaded_files) ->
        # Merge new uploads with existing ones
        upload_params =
          Enum.reduce(Enum.with_index(uploaded_files), upload_params, fn {uploaded_file, index},
                                                                         acc ->
            # Use the next available index for the new file
            Map.put(acc, "#{length(Map.keys(upload_params)) + index}", uploaded_file)
          end)

        # Update the params with the new uploads
        Map.put(
          params,
          "#{field_key}",
          upload_params
        )
    end
  end

  @doc """
  Processes a single uploaded file and prepares it for insertion into database records.

  Similar to `consume_uploads/4` but designed for single file uploads. It expects only
  one file to be uploaded at a time.

  ## Parameters

  * `socket` - The LiveView socket with uploads
  * `params` - The params map (usually from the form submission)
  * `field_key` - The atom key of the upload field
  * `options` - A keyword list of options
    * `:generate_name` - When true, generates a unique UUID for the filename (default: false)
    * `:merge_fun` - A function that merges the uploaded file path into params (default: simple Map.put)

  ## Returns

  The updated params map with the uploaded file merged in.

  ## Examples

  ```elixir
  # In a LiveView handle_event function
  def handle_event("save", %{"user" => user_params}, socket) do
    user_params =
      PhoenixImageTools.Components.consume_upload(
        socket, 
        user_params, 
        :avatar, 
        generate_name: true
      )
    
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        {:noreply, socket |> put_flash(:info, "Profile updated") |> assign(:user, user)}
      
      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
  ```

  With custom merge function:

  ```elixir
  # Custom merge that handles nested params
  merge_fun = fn params, key, uploaded_file ->
    put_in(params, ["profile", "{key}"], uploaded_file)
  end

  PhoenixImageTools.Components.consume_upload(
    socket, 
    user_params, 
    :avatar, 
    generate_name: true,
    merge_fun: merge_fun
  )
  ```
  """
  @spec consume_upload(Socket.t(), map(), atom(), keyword()) :: map()
  def consume_upload(socket, params, field_key, options \\ [])
      when is_atom(field_key) and is_map(params) do
    defaults = [
      generate_name: false,
      extension: "image",
      merge_fun: fn params, key, uploaded_file ->
        Map.put(
          params,
          "#{key}",
          uploaded_file
        )
      end
    ]

    options = options |> Keyword.validate!(defaults) |> Map.new()

    case Phoenix.LiveView.consume_uploaded_entries(socket, field_key, fn %{path: path}, entry ->
           # Add the file extension to the temp file
           path_with_extension =
             path <> String.replace(entry.client_type, "#{options.extension}/", ".")

           # Generate unique filename if requested
           path_with_extension =
             if options.generate_name do
               dir_name = Path.dirname(path_with_extension)
               file_name = "#{Ecto.UUID.generate()}#{Path.extname(path_with_extension)}"
               Path.join([dir_name, file_name])
             else
               path_with_extension
             end

           # Create a copy with the correct extension
           File.cp!(path, path_with_extension)

           # Return just the path for single file uploads
           {:ok, path_with_extension}
         end) do
      [] ->
        # No file uploaded, return params unchanged
        params

      [uploaded_file] ->
        # Use the provided merge function to update params
        options.merge_fun.(params, field_key, uploaded_file)

      multiple_files when is_list(multiple_files) ->
        # Warn about multiple files but just use the first one
        IO.warn(
          "Multiple files uploaded for single file field #{field_key}, using only the first one."
        )

        options.merge_fun.(params, field_key, List.first(multiple_files))
    end
  end

  @doc """
  Determines if a file is an image based on its extension.

  Checks if a given filename has a supported image extension.

  ## Parameters

  * `file_name` - The filename or path to check

  ## Returns

  Boolean indicating if the file has a supported image extension

  ## Examples

  ```elixir
  iex> PhoenixImageTools.Components.is_image?("photo.jpg")
  true

  iex> PhoenixImageTools.Components.is_image?("document.pdf")
  false
  ```
  """
  @image_extensions ~w(.jpg .jpeg .gif .png .webp)
  @spec is_image?(String.t()) :: boolean()
  def is_image?(file_name) when is_binary(file_name) do
    file_extension = file_name |> Path.extname() |> String.downcase()
    Enum.member?(@image_extensions, file_extension)
  end
end
