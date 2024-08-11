defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view
  alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item}
  alias Auth2024.Todos
  alias Auth2024Web.Tools

  @topic "page_live"

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


  defp editing_contact_datalist(
    user, 
    %Phoenix.LiveView.Socket{} = socket,
    _text
  ) do
    persons = Todos.list_persons!(user)
    #persons = if nil != text && String.length(text)>1 do
    #  Todos.search_persons_beginning(text)
    #else
    #  Todos.
    #end
    persons = if persons == [] do
      [socket.assigns.current_person]
    else
      persons
    end
    persons
  end


  # This is specific for caption
  defp default_editing_item_values(
    %Phoenix.LiveView.Socket{} = socket, text
  ) do
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


  defp query_items(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    Todos.list_items(
      socket.assigns.current_user, 
      socket.assigns.filter_by_value,
      socket.assigns.sort_by_column
    )
  end


  defp default_assigns() do
    %{
      editing_item: nil,
      editing_kind: nil,
      current_user: nil,
      current_item: nil,
      current_person: nil,
      editing_item_datalist: [],
      items: nil,
      filter_by_value: "active",
      sort_by_column: "date",
      available_persons: []
    }
  end


  @impl true
  def mount(
    _params, session, %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = default_assigns()
    # subscribe to the channel
    if connected?(socket), do: Auth2024Web.Endpoint.subscribe(@topic)
    with token when is_bitstring(token) <- session["user_token"],
      user when not is_nil(user) <- Auth2024.Accounts.get_user_by_session_token(token) do
        current_person = Todos.find_person_for_user(user)
        items = Todos.list_items(
          user, 
          default_assigns.filter_by_value, 
          default_assigns.sort_by_column
        )
      {:ok, 
        socket 
        |> assign(default_assigns) 
        |> assign(
            current_user: user,
            current_person: current_person,
            items: items,
            available_persons: editing_contact_datalist(user, socket, ""),
            editing_item_values: empty_editing_item_values()
        )
      }
    else
      _ -> {:ok, socket}
    end
  end


 def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    socket = socket 
      |> assign(
      items: query_items(socket),
      editing_item: nil,
      editing_kind: nil,
      editing_item_datalist: [],
      editing_item_values: empty_editing_item_values()
      )
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    socket
  end


  @doc """
  Finalize the editing by saving the data to the databse.
  """
  def save_edit_done(
    %Phoenix.LiveView.Socket{} = socket,
    item_id,
    kind, 
    value
  ) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(item_id)
    # IO.inspect(current_item)
    case kind do
      :caption ->
        Todos.update_item(user, current_item, Tools.easy_changeset_attrs(kind, value))
      :due ->
        Todos.update_item(user, current_item, Tools.easy_changeset_attrs(kind, value))
      :contact ->
        Todos.update_item_contact(user, current_item, %{:contact => value})
        #Todos.update_item(user, current_item, Tools.easy_changeset_attrs(kind, value))
    end
    socket |> just_edit_done()
  end


  @doc """
  Find associated data with the new value in the database or other
  sources, possibly cancelling the edit or opening a modal user flow.

  This function either terminates the flow or continues using a modal
  or calls save_edit_done.

  returns socket
  """
  def find_edit_done(
    %Phoenix.LiveView.Socket{} = socket, 
    item_id,
    kind, 
    value
  ) do
    # user = socket.assigns.current_user
    # current_item = Todos.get_item!(socket.assigns.editing_item)
    case kind do
      :due ->
        socket |> save_edit_done(item_id, kind, value)
    end
  end

  # TXWTODO: A proper validation path is missing, we are directly going into the
  # save path, treating validation as a special case.


  @impl true
  def handle_event(
    "create", 
    %{"text" => text}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    Todos.add_item(socket.assigns.current_user, default_editing_item_values(socket, text));
    socket = assign(socket, 
      items: query_items(socket), 
      active: %Item{}
    )
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event(
    "delete", 
    data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    user = socket.assigns.current_user
    Todos.delete_item(user, Map.get(data, "item_id"))
    socket = assign(socket, 
      items: query_items(socket), 
      active: %Item{}
    )
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def handle_event("toggle", data, socket) do
    user = socket.assigns.current_user
	  status = if Map.has_key?(data, "value"), do: 1, else: 0
	  item = Todos.get_item!(Map.get(data, "item_id"))
	  Todos.update_item(user, item, %{status: status})
    socket = assign(socket, 
      items: query_items(socket), 
      active: %Item{}
    )
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  def handle_event(
    "submit-todo-item-due", 
    %{"item_id" => item_id, "duedate" => datetext}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {
      :noreply, 
      socket
      |> assign(editing_item: item_id)
      |> find_edit_done(item_id, :due, datetext)
    }
  end


  @impl true
  def handle_event(
    "validate-todo-item-due", 
    %{"_target" => _target, "duedate" => datetext}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values,
        :due,  datetext))}
  end


  @impl true
  def handle_params(
    params, 
    _url, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    user = socket.assigns.current_user

    sort_by_column = if Map.has_key?(params, "sort_by") do params["sort_by"] else socket.assigns.sort_by_column end
    filter_by_value = if Map.has_key?(params, "filter_by") do params["filter_by"] else socket.assigns.filter_by_value end

    {:noreply,
      assign(socket,
        sort_by_column: sort_by_column,
        filter_by_value: filter_by_value,
        items: Todos.list_items(user, filter_by_value, sort_by_column)
      )
    }
  end

  # Called by the contact changed box.
  def handle_info(
    %{event: "on_itemlist_itemfield_changed", item_id: item_id, kind: kind, value: value},
    socket
  ) do
    {
      :noreply,
      socket
      |> save_edit_done(item_id, kind, value)
    }
  end


  def handle_info(
    %{event: "on_editing_item", item_id: item_id},
    socket
  ) do
    {
      :noreply,
      socket
      |> assign(editing_item: item_id)
    }
  end


  def handle_info(
    %{event: "confirm_new_person_onperson", confirmed_person: person},
    socket
  ) do
    new_assigns = %{
      available_persons: Todos.list_persons!(socket.assigns.current_user),
    }
    IO.inspect("confirm_new_person_onperson")
    IO.inspect(socket.assigns)
    #socket
    {:noreply,
      socket
      |> save_edit_done(socket.assigns.editing_item, :contact, person)
      |> assign(new_assigns)
      |> push_event("close_modal", %{to: "#confirm-new-person"})
    }
  end


  def handle_info(
    %{event: "edit_todo_onitem", changed_item: _item},
    socket
  ) do
    #socket
    {:noreply,
      socket
      |> just_edit_done()
    }
  end


  @impl true
  def handle_info(
    %{event: "update", payload: %{items: items}}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
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

end
