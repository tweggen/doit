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
    %{due: nil}
  end


  defp default_editing_item_values(socket, text) do
    {erl_date, _erl_time} = :calendar.local_time()
    {:ok, date} = Date.from_erl(erl_date)
    %{
      caption: text,
      status: 0,
      author: socket.assigns.current_person,
      contact: socket.assigns.current_person,
      due: date
    }
  end


  def push_js(socket, to, js) do
    event_details = %{
      to: to,
      encodedJS: Phoenix.json_library().encode!(js.ops)
    }

    socket
    |> Phoenix.LiveView.push_event("exec-js", event_details);
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
          create_confirm_new_person_form: nil,
          current_user: user,
          current_person: current_person,
          items: items,
          editing_item: nil,
          editing_kind: nil,
          editing_item_datalist: [],
          editing_item_values: empty_editing_item_values(),
          tab: "all")}
    else
      _ -> {:ok, socket}
    end
  end


  defp easy_changeset_attrs(kind, value) do
    %{kind => value}
  end


  defp possibly_update_item_contact(socket, user, current_item, contact_person_name) do
    contact_person = Todos.search_person_family_name(contact_person_name)
    IO.inspect(["contact person", contact_person_name, contact_person])
    IO.inspect(["current_item", current_item])
    
    if contact_person != nil do
      Todos.update_item_contact(user, current_item, easy_changeset_attrs(:contact, contact_person))
      socket
    else
      IO.inspect("Unknown person, ask for new")
      socket |> push_js("confirm-new-person", Auth2024Web.CoreComponents.show_modal("confirm-new-person"))
    end
  end


  def do_edit_done(socket, item_id, kind, value) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(item_id)
    socket = case kind do
      :caption -> 
        Todos.update_item_caption(user, current_item, easy_changeset_attrs(kind, value))
        socket
      :due ->
        Todos.update_item_due(user, current_item, easy_changeset_attrs(kind, value))
        socket
      :contact ->
        socket |> possibly_update_item_contact(user, current_item, value)
    end
    items = Todos.list_items(user)
    socket = assign(socket,
      items: items,
      editing_item: nil,
      editing_kind: nil,
      editing_item_datalist: [],
      editing_item_values: empty_editing_item_values()
    )
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event("create-new-person-submit", _data, socket) do
    #Auth2024Web.CoreComponents.hide_modal("confirm-new-person")
    IO.inspect("create-new-person-submit called.")
    #Auth2024Web.CoreComponents.hide_modal("confirm-new-person")
    #Auth2024Web.CoreComponents.hide_modal("confirm-new-person")
    #socket = socket
    #  |> push_event("data-cancel", %{to: "#confirm-new-person"})
    socket =
        socket
        #|> assign(new_assigns)
        |> push_event("close_modal", %{to: "#confirm-new-person"})
    {:noreply, socket}
  end


  @impl true
  def handle_event("create", %{"text" => text}, socket) do
    Todos.add_item(socket.assigns.current_user, default_editing_item_values(socket, text));
    socket = assign(socket, items: Todos.list_items(socket.assigns.current_user), active: %Item{})
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
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
  def handle_event("toggle", data, socket) do
    user = socket.assigns.current_user
	  status = if Map.has_key?(data, "value"), do: 1, else: 0
	  item = Todos.get_item!(Map.get(data, "id"))
	  Todos.update_item(user, item, %{status: status})
	  socket = assign(socket, items: Todos.list_items(user), active: %Item{})
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @doc """
  Activates editing the item's caption.
  """
  @impl true
  def handle_event("edit-item-caption", data, socket) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(empty_editing_item_values(),
          :caption, data["text"]),
        editing_kind: :caption,
        editing_item: String.to_integer(data["id"]),
        editing_item_datalist: []
      )
    }
  end


  def handle_event("submit-todo-item-caption", %{"id" => item_id, "text" => text}, socket) do
    do_edit_done(socket, item_id, :caption, text)
  end


  @impl true
  def handle_event("validate-todo-item-caption", %{"_target" => _target, "text" => text}, socket) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values,
        :caption,  text))}
  end


  @impl true
  def handle_event("edit-item-contact", data, socket) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(empty_editing_item_values(),
          :contact, data["text"]),
        editing_kind: :contact,
        editing_item: String.to_integer(data["id"]),
        editing_item_datalist: []
      )
    }
  end


  def handle_event("submit-todo-item-contact", %{"id" => item_id, "text" => text}, socket) do
    do_edit_done(socket, item_id, :contact, text)
  end


  @impl true
  def handle_event("validate-todo-item-contact", %{"_target" => _target, "text" => text}, socket) do
    persons = if nil != text && String.length(text)>1 do
      Todos.search_persons_beginning(text)
    else
      []
    end
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values,
          :contact,  text),
        editing_item_datalist: persons
      )
    }
  end


  def handle_event("submit-todo-item-due", %{"item_id" => item_id, "duedate" => datetext}, socket) do
    do_edit_done(socket, item_id, :due, datetext)
  end


  @impl true
  def handle_event("validate-todo-item-due", %{"_target" => _target, "duedate" => datetext}, socket) do
    IO.inspect(["validate due", datetext])
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values,
        :due,  datetext))}
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


  def form_todo_item_due_id(item) do
    "form-todo-item-due-#{item.id}"
  end

  def display_due_date(item) do
    if is_nil(item.due) do
      # Get the current local date
      current_date = :calendar.local_time()

      # Format the date as "YYYY-MM-DD"
      formatted_date = Timex.format!(current_date, "{YYYY}-{0M}-{0D}")
      formatted_date
    else
      Date.to_string(item.due)
    end
  end

end
