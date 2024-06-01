defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view
  alias Auth2024.Todo.Item
  alias Auth2024.Todos

  @topic "live"

  @impl true
  def mount(_params, _session, socket) do
    # subscribe to the channel
    if connected?(socket), do: Auth2024Web.Endpoint.subscribe(@topic)
    {:ok, assign(socket, items: Todos.list_items())} # add items to assigns
  end

  @impl true
  def handle_event("create", %{"text" => text}, socket) do
    Todos.add_item(%{caption: text})
    socket = assign(socket, items: Todos.list_items(), active: %Item{})
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle", data, socket) do
	status = if Map.has_key?(data, "value"), do: 1, else: 0
	item = Todos.get_item!(Map.get(data, "id"))
	Todos.update_item(item, %{id: item.id, status: status})
	socket = assign(socket, items: Todos.list_items(), active: %Item{})
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", data, socket) do
    Todos.delete_item(Map.get(data, "id"))
    socket = assign(socket, items: Todos.list_items(), active: %Item{})
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "update", payload: %{items: items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end

  def checked?(item) do
    not is_nil(item.status) and item.status > 0
  end

  def completed?(item) do
    if not is_nil(item.status) and item.status > 0, do: "completed", else: ""
  end

end