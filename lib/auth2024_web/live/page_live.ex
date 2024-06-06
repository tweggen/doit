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


  defp empty_editing_item_values() do
    %{caption: nil}
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
          editing_item: nil,
          editing_item_values: empty_editing_item_values(),
          tab: "all")}
    else
      _ -> {:ok, socket}
    end
  end


  def do_edit_done(socket, item_id, kind, value) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(item_id)
    Todos.update_item_caption(user, current_item, %{kind => value})
    items = Todos.list_items(user)
    socket = assign(socket, editing_item_values: empty_editing_item_values(), items: items, editing_item: nil)
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
    {:noreply, 
      assign(socket, 
        editing_item_values: Map.put(empty_editing_item_values(),
          :caption, data["text"]),
        editing_item: String.to_integer(data["id"]))}
  end


  @impl true
  def handle_event("submit-todo-item", %{"id" => item_id, "text" => text}, socket) do
    do_edit_done(socket, item_id, :caption, text)
  end


  @impl true
  def handle_event("validate-todo-item", %{"_target" => _target, "text" => text}, socket) do
    {:noreply, 
      assign(socket, 
      editing_item_values: Map.put(socket.assigns.editing_item_values,
        :caption,  text))}
  end


  @impl true
  def handle_event("left-todo-item", _data, socket) do
    do_edit_done(socket, socket.assigns.editing, :caption, socket.assigns.editing_item_values.caption)
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

  def display_due_date(item) do
    if is_nil(item.due) do
      # Get the current local date
      current_date = :calendar.local_time()

      # Format the date as "YYYY-MM-DD"
      formatted_date = Timex.format!(current_date, "{YYYY}-{0M}-{0D}")
      formatted_date
    else
      item.due.to_string()
    end
  end

end