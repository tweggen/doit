defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view
  alias Auth2024.Todo.Item
  alias Auth2024.Todos

  @topic "live"

  @impl true
  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end

  @impl true
  def mount(_params, session, socket) do
    # subscribe to the channel
    if connected?(socket), do: Auth2024Web.Endpoint.subscribe(@topic)
    with token when is_bitstring(token) <- session["user_token"],
      user when not is_nil(user) <- Auth2024.Accounts.get_user_by_session_token(token) do
        current_person = Todos.find_person(user)
        items = Todos.list_items(user)
      {:ok, 
        assign(socket, 
          current_user: user, 
          current_person: current_person,
          items: items,
          editing: nil,
          editing_item_caption: nil,
          tab: "all")}
    else
      _ -> {:ok, socket}
    end
  end


  def do_edit_done(socket, item_id, text) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(item_id)
    Todos.update_item_caption(user, current_item, %{caption: text})
    items = Todos.list_items(user)
    IO.inspect(items)
    socket = assign(socket, items: items, editing: nil, editing_item_caption: nil)
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event("create", %{"text" => text}, socket) do
    Todos.add_item(socket.assigns.current_user, %{caption: text, status: 0, author: socket.assigns.current_person, contact: socket.assigns.current_person})
    socket = assign(socket, items: Todos.list_items(socket.assigns.current_user), active: %Item{})
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event("toggle", data, socket) do
    user = socket.assigns.current_user
	  status = if Map.has_key?(data, "value"), do: 1, else: 0
	  item = Todos.get_item!(Map.get(data, "id"))
	  Todos.update_item(user, item, %{status: status})
	  socket = assign(socket, items: Todos.list_items(user), active: %Item{})
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event("edit-item", data, socket) do
    #IO.inspect("edit called")
    #IO.inspect(data)
    {:noreply, 
      assign(socket, 
        editing_item_caption: data["text"],
        editing: String.to_integer(data["id"]))}
  end


  @impl true
  def handle_event("submit-todo-item", %{"id" => item_id, "text" => text}, socket) do
    #IO.inspect("submit called")
    do_edit_done(socket, item_id, text)
  end


  @impl true
  def handle_event("validate-todo-item", %{"_target" => _target, "text" => text}, socket) do
    #IO.inspect("validate called")
    #IO.inspect(text)
    {:noreply, assign(socket, editing_item_caption: text)}
  end


  @impl true
  def handle_event("left-todo-item", _data, socket) do
    #IO.inspect("left called")
    #IO.inspect(socket.assigns.editing)
    do_edit_done(socket, socket.assigns.editing, socket.assigns.editing_item_caption)
    {:noreply, socket}
  end


  @impl true
  def handle_event("delete", data, socket) do
    user = socket.assigns.current_user
    Todos.delete_item(user, Map.get(data, "id"))
    socket = assign(socket, items: Todos.list_items(socket.assigns.current_user), active: %Item{})
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.current_user
    items = Todos.list_items(user)

    case params["filter_by"] do
      "completed" ->
        completed = Enum.filter(items, &(&1.status == 1))
        {:noreply, assign(socket, items: completed, tab: "completed")}

      "active" ->
        active = Enum.filter(items, &(&1.status == 0))
        {:noreply, assign(socket, items: active, tab: "active")}

      _ ->
        {:noreply, assign(socket, items: items, tab: "all")}
    end
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