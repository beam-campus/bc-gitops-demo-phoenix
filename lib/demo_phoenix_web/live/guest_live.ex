defmodule DemoPhoenixWeb.GuestLive do
  @moduledoc """
  A simple guest book LiveView to demonstrate Phoenix LiveView features.
  Deployed and managed by bc_gitops.
  """
  use DemoPhoenixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:guests, load_guests())
      |> assign(:form, to_form(%{"name" => "", "message" => ""}))
      |> assign(:visitor_count, :rand.uniform(1000) + 500)

    if connected?(socket) do
      :timer.send_interval(5000, self(), :tick)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :visitor_count, socket.assigns.visitor_count + :rand.uniform(3))}
  end

  @impl true
  def handle_event("submit", %{"name" => name, "message" => message}, socket) do
    guest = %{
      id: System.unique_integer([:positive]),
      name: String.trim(name),
      message: String.trim(message),
      timestamp: DateTime.utc_now()
    }

    guests =
      if valid_guest?(guest) do
        save_guest(guest)
        [guest | socket.assigns.guests] |> Enum.take(20)
      else
        socket.assigns.guests
      end

    socket =
      socket
      |> assign(:guests, guests)
      |> assign(:form, to_form(%{"name" => "", "message" => ""}))

    {:noreply, socket}
  end

  def handle_event("clear", _params, socket) do
    clear_guests()
    {:noreply, assign(socket, :guests, [])}
  end

  defp valid_guest?(%{name: name, message: message}) do
    String.length(name) > 0 and String.length(message) > 0
  end

  # Simple ETS-based persistence (in-memory, lost on restart)
  defp load_guests do
    case :ets.whereis(:demo_phoenix_guests) do
      :undefined ->
        :ets.new(:demo_phoenix_guests, [:named_table, :public, :ordered_set])
        []
      _ ->
        :ets.tab2list(:demo_phoenix_guests)
        |> Enum.sort_by(fn {id, _} -> -id end)
        |> Enum.map(fn {_, guest} -> guest end)
        |> Enum.take(20)
    end
  end

  defp save_guest(guest) do
    :ets.insert(:demo_phoenix_guests, {guest.id, guest})
  end

  defp clear_guests do
    case :ets.whereis(:demo_phoenix_guests) do
      :undefined -> :ok
      _ -> :ets.delete_all_objects(:demo_phoenix_guests)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-800">
      <div class="max-w-4xl mx-auto py-12 px-4">
        <!-- Header -->
        <div class="text-center mb-12">
          <h1 class="text-5xl font-bold text-white mb-4">
            Guest Book
          </h1>
          <p class="text-purple-200 text-lg">
            A Phoenix LiveView app managed by
            <span class="font-mono bg-purple-800/50 px-2 py-1 rounded">bc_gitops</span>
          </p>
          <div class="mt-4 inline-flex items-center gap-2 bg-white/10 rounded-full px-4 py-2">
            <span class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
            <span class="text-purple-200 text-sm">
              <%= @visitor_count %> visitors
            </span>
          </div>
        </div>

        <!-- Sign the Guest Book -->
        <div class="bg-white/10 backdrop-blur-lg rounded-2xl p-6 mb-8 border border-white/20">
          <h2 class="text-xl font-semibold text-white mb-4">Sign the Guest Book</h2>
          <.form for={@form} phx-submit="submit" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-purple-200 text-sm mb-1">Your Name</label>
                <input
                  type="text"
                  name="name"
                  value={@form[:name].value}
                  placeholder="Enter your name"
                  class="w-full px-4 py-2 rounded-lg bg-white/10 border border-white/20 text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-400"
                  required
                />
              </div>
              <div>
                <label class="block text-purple-200 text-sm mb-1">Message</label>
                <input
                  type="text"
                  name="message"
                  value={@form[:message].value}
                  placeholder="Leave a message..."
                  class="w-full px-4 py-2 rounded-lg bg-white/10 border border-white/20 text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-400"
                  required
                />
              </div>
            </div>
            <div class="flex gap-3">
              <button
                type="submit"
                class="px-6 py-2 bg-purple-600 hover:bg-purple-500 text-white font-medium rounded-lg transition-colors"
              >
                Sign Guest Book
              </button>
              <button
                type="button"
                phx-click="clear"
                class="px-4 py-2 bg-white/10 hover:bg-white/20 text-purple-200 rounded-lg transition-colors"
              >
                Clear All
              </button>
            </div>
          </.form>
        </div>

        <!-- Guest Entries -->
        <div class="space-y-4">
          <h2 class="text-xl font-semibold text-white">
            Recent Guests
            <span class="text-purple-300 text-sm font-normal ml-2">
              (<%= length(@guests) %> entries)
            </span>
          </h2>

          <%= if @guests == [] do %>
            <div class="bg-white/5 rounded-xl p-8 text-center border border-white/10">
              <p class="text-purple-300">No guests yet. Be the first to sign!</p>
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for guest <- @guests do %>
                <div class="bg-white/10 backdrop-blur rounded-xl p-4 border border-white/10 hover:bg-white/15 transition-colors">
                  <div class="flex justify-between items-start">
                    <div>
                      <p class="font-semibold text-white"><%= guest.name %></p>
                      <p class="text-purple-200 mt-1"><%= guest.message %></p>
                    </div>
                    <span class="text-purple-400 text-xs">
                      <%= Calendar.strftime(guest.timestamp, "%H:%M:%S") %>
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- Footer -->
        <div class="mt-12 text-center text-purple-300 text-sm">
          <p>
            This app runs on port
            <span class="font-mono bg-purple-800/50 px-2 py-0.5 rounded">4001</span>
            and is deployed via GitOps
          </p>
          <p class="mt-2 font-mono text-xs text-purple-400">
            Phoenix LiveView • Hot Code Reload • bc_gitops
          </p>
        </div>
      </div>
    </div>
    """
  end
end
