defmodule DemoPhoenixWeb.GuestComponent do
  @moduledoc """
  A LiveComponent that can be embedded in host applications via bc_gitops.

  This component receives assigns from the host and maintains its own state.
  It demonstrates how guest applications can expose UI components that integrate
  seamlessly into a host dashboard.

  ## Required assigns from host:
    - `:id` - unique identifier for this component instance

  ## Optional assigns from host:
    - `:host_app` - name of the host application
    - `:theme` - "light" or "dark" (default: "dark")
  """
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:guests, load_guests())
      |> assign(:form, to_form(%{"name" => "", "message" => ""}))
      |> assign_new(:theme, fn -> "dark" end)
      |> assign_new(:host_app, fn -> "unknown" end)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:guests, load_guests())

    {:ok, socket}
  end

  @impl true
  def handle_event("submit", %{"name" => name, "message" => message}, socket) do
    guest = %{
      id: System.unique_integer([:positive]),
      name: String.trim(name),
      message: String.trim(message),
      timestamp: DateTime.utc_now(),
      from_host: socket.assigns[:host_app]
    }

    if valid_guest?(guest) do
      save_guest(guest)
    end

    socket =
      socket
      |> assign(:guests, load_guests())
      |> assign(:form, to_form(%{"name" => "", "message" => ""}))

    {:noreply, socket}
  end

  def handle_event("clear", _params, socket) do
    clear_guests()
    {:noreply, assign(socket, :guests, [])}
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, assign(socket, :guests, load_guests())}
  end

  defp valid_guest?(%{name: name, message: message}) do
    String.length(name) > 0 and String.length(message) > 0
  end

  # ETS-based persistence
  defp ensure_table do
    case :ets.whereis(:demo_phoenix_guests) do
      :undefined -> :ets.new(:demo_phoenix_guests, [:named_table, :public, :ordered_set])
      tid -> tid
    end
  end

  defp load_guests do
    ensure_table()
    :ets.tab2list(:demo_phoenix_guests)
    |> Enum.sort_by(fn {id, _} -> -id end)
    |> Enum.map(fn {_, guest} -> guest end)
    |> Enum.take(15)
  end

  defp save_guest(guest) do
    ensure_table()
    :ets.insert(:demo_phoenix_guests, {guest.id, guest})
  end

  defp clear_guests do
    ensure_table()
    :ets.delete_all_objects(:demo_phoenix_guests)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={theme_classes(@theme)}>
      <div class="p-6">
        <!-- Header -->
        <div class="flex justify-between items-center mb-6">
          <div>
            <h2 class="text-2xl font-bold">Guest Book</h2>
            <p class="text-sm opacity-70 mt-1">
              LiveComponent from <span class="font-mono">demo_phoenix</span>
            </p>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs opacity-50">
              Hosted by: <%= @host_app %>
            </span>
            <button
              phx-click="refresh"
              phx-target={@myself}
              class="p-2 rounded-lg hover:bg-white/10 transition-colors"
              title="Refresh"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
              </svg>
            </button>
          </div>
        </div>

        <!-- Form -->
        <form phx-submit="submit" phx-target={@myself} class="mb-6">
          <div class="flex gap-3">
            <input
              type="text"
              name="name"
              value={@form[:name].value}
              placeholder="Your name"
              required
              class={input_classes(@theme)}
            />
            <input
              type="text"
              name="message"
              value={@form[:message].value}
              placeholder="Leave a message..."
              required
              class={input_classes(@theme) <> " flex-1"}
            />
            <button type="submit" class={button_classes(@theme)}>
              Sign
            </button>
          </div>
        </form>

        <!-- Guest List -->
        <div class="space-y-2 max-h-64 overflow-y-auto">
          <%= if @guests == [] do %>
            <p class="text-center py-4 opacity-50">No guests yet. Be the first!</p>
          <% else %>
            <%= for guest <- @guests do %>
              <div class={entry_classes(@theme)}>
                <div class="flex justify-between items-start">
                  <div>
                    <span class="font-medium"><%= guest.name %></span>
                    <span class="opacity-50 mx-2">&mdash;</span>
                    <span class="opacity-80"><%= guest.message %></span>
                  </div>
                  <span class="text-xs opacity-40 whitespace-nowrap ml-4">
                    <%= Calendar.strftime(guest.timestamp, "%H:%M") %>
                  </span>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <!-- Footer -->
        <div class="mt-4 pt-4 border-t border-current/10 flex justify-between items-center text-xs opacity-50">
          <span><%= length(@guests) %> entries</span>
          <button
            phx-click="clear"
            phx-target={@myself}
            class="hover:opacity-100 transition-opacity"
          >
            Clear all
          </button>
        </div>
      </div>
    </div>
    """
  end

  # Theme-aware styling
  defp theme_classes("light"), do: "bg-white text-gray-900 rounded-xl border border-gray-200"
  defp theme_classes(_), do: "bg-gray-800 text-gray-100 rounded-xl border border-gray-700"

  defp input_classes("light") do
    "px-3 py-2 rounded-lg border border-gray-300 bg-white text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
  end
  defp input_classes(_) do
    "px-3 py-2 rounded-lg border border-gray-600 bg-gray-700 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
  end

  defp button_classes("light") do
    "px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-lg transition-colors"
  end
  defp button_classes(_) do
    "px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white font-medium rounded-lg transition-colors"
  end

  defp entry_classes("light") do
    "p-3 rounded-lg bg-gray-50 border border-gray-100"
  end
  defp entry_classes(_) do
    "p-3 rounded-lg bg-gray-700/50 border border-gray-600/50"
  end
end
