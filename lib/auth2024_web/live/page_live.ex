defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view
  alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item,Person}
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


  defp editing_contact_datalist(
    user, 
    %Phoenix.LiveView.Socket{} = socket,
    text
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
    IO.inspect(persons)
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


  def push_js(
    %Phoenix.LiveView.Socket{} = socket, to, js
  ) do
    event_details = %{
      to: to,
      encodedJS: Phoenix.json_library().encode!(js.ops)
    }
    socket |> Phoenix.LiveView.push_event("exec-js", event_details);
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


  @impl true
  def mount(
    _params, session, %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{
      create_confirm_new_person_form: nil,
      editing_item: nil,
      editing_kind: nil,
      current_user: nil,
      current_person: nil,
      editing_item_datalist: [],
      items: nil,
      new_person_form: Phoenix.Component.to_form(Person.create_changeset(%{})),
      filter_by_value: "all",
      sort_by_column: "date"
    }
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
            editing_item_values: empty_editing_item_values()
        )
      }
    else
      _ -> {:ok, socket}
    end
  end


  defp easy_changeset_attrs(kind, value) do
    %{kind => value}
  end


  defp possibly_update_item_contact(
    %Phoenix.LiveView.Socket{} = socket, 
    user, 
    current_item, 
    contact_person_name
  ) do
    contact_person = Todos.search_person_family_name(contact_person_name)
    IO.inspect(["contact person", contact_person_name, contact_person])
    IO.inspect(["current_item", current_item])
    
    if contact_person != nil do
      IO.inspect(contact_person)
      socket |> save_edit_done(:contact, contact_person)
    else
      socket 
      |> push_js("confirm-new-person", 
          %JS{} 
          |> JS.set_attribute({"value", contact_person_name}, to: "#new-person-form-family-name")
          )
      |> push_js("confirm-new-person", Auth2024Web.CoreComponents.show_modal("confirm-new-person"))
    end
  end


  def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    IO.inspect("just_edit_done")
    user = socket.assigns.current_user
    socket = socket |> assign(
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
  Find associated data with the new value in the database or other
  sources, possibly cancelling the edit or opening a modal user flow.

  This function either terminates the flow or continues using a modal
  or calls save_edit_done.

  returns socket
  """
  def find_edit_done(
    %Phoenix.LiveView.Socket{} = socket, 
    kind, 
    value
  ) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(socket.assigns.editing_item)
    socket = case kind do
      :caption ->
        socket |> save_edit_done(kind, value)
      :due ->
        socket |> save_edit_done(kind, value)
      :contact ->
        socket |> possibly_update_item_contact(user, current_item, value)
    end
  end

  # TXWTODO: A proper validation path is missing, we are directly going into the
  # save path, treating validation as a special case.


  @doc """
  Finalize the editing by saving the data to the databse.
  """
  def save_edit_done(
    %Phoenix.LiveView.Socket{} = socket,
    kind, 
    value
  ) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(socket.assigns.editing_item)
    case kind do
      :caption -> 
        Todos.update_item_caption(user, current_item, easy_changeset_attrs(kind, value))
      :due ->
        Todos.update_item_due(user, current_item, easy_changeset_attrs(kind, value))
      :contact ->
        Todos.update_item_contact(user, current_item, easy_changeset_attrs(kind, value))
    end
    socket |> just_edit_done()
  end

  @impl true
  def handle_event(
    "blur-plus",
    %{"relatedTarget" => related_target_id},
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect(related_target_id)
  end


  @impl true
  def handle_event(
    "create-new-person-submit",
    %{"person" => person_params},
    %Phoenix.LiveView.Socket{} = socket
  ) do
    user = socket.assigns.current_user
    current_item = Todos.get_item!(socket.assigns.editing_item)
    case Todos.add_person(user, Map.merge(person_params, %{"status" => 0})) do
      {:error, message} ->
        {:noreply, socket |> put_flash(:error, inspect(message))}

      {:ok, person} ->

        new_assigns = %{
          new_person_form: Phoenix.Component.to_form(Person.create_changeset(%{})),
        }

        socket 
        |> save_edit_done(:contact, person)
        |> assign(new_assigns)
        |> push_event("close_modal", %{to: "#confirm-new-person"})

        {:noreply, socket}
    end
  end


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
    Todos.delete_item(user, Map.get(data, "id"))
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
	  item = Todos.get_item!(Map.get(data, "id"))
	  Todos.update_item(user, item, %{status: status})
    socket = assign(socket, 
      items: query_items(socket), 
      active: %Item{}
    )
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @doc """
  Activates editing the item's caption.
  """
  @impl true
  def handle_event(
    "edit-item-caption", 
    data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
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


  def handle_event(
    "submit-todo-item-caption", 
    %{"id" => item_id, "text" => text},
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply, find_edit_done(socket, :caption, text)}
  end


  @impl true
  def handle_event(
    "validate-todo-item-caption",
    %{"_target" => _target, "text" => text}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values,
        :caption,  text))}
  end


  @impl true
  def handle_event(
    "edit-item-contact",
    data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(empty_editing_item_values(),
          :contact, data["text"]),
        editing_kind: :contact,
        editing_item: String.to_integer(data["id"]),
        editing_item_datalist: editing_contact_datalist(socket.assigns.current_user, socket, "")
      )
    }
  end


  @impl true
  def handle_event(
    "click-item-contact-select",
    data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(empty_editing_item_values(), :contact, data["text"]),
        editing_kind: :contact,
        editing_item: String.to_integer(data["id"]),
        editing_item_datalist: editing_contact_datalist(socket.assigns.current_user, socket, "")
      )
    }
  end


  @impl true
  def handle_event(
    "change-item-contact-select",
    %{"value" => value}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    if value="Create new..." do
      socket 
      #|> push_js("confirm-new-person", 
      #    %JS{} 
      #    |> JS.set_attribute({"value", contact_person_name}, to: "#new-person-form-family-name")
      #    )
      |> push_js("confirm-new-person", Auth2024Web.CoreComponents.show_modal("confirm-new-person"))
      { :noreply, socket }
    else 
      { :noreply, find_edit_done(socket, :contact, value) }
    end
  end


  def handle_event(
    "submit-todo-item-contact", 
    %{"id" => _item_id, "text" => text}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply, find_edit_done(socket, :contact, text)}
  end


  @impl true
  def handle_event(
    "validate-todo-item-contact", 
    %{"_target" => _target, "text" => text}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_values: Map.put(socket.assigns.editing_item_values, :contact, text),
        editing_item_datalist: editing_contact_datalist(socket.assigns.current_user, socket, text)
      )
    }
  end


  @impl true
  def handle_event(
    "load-todo-item-contacts", 
    _data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply,
      assign(socket,
        editing_item_datalist: editing_contact_datalist(socket.assigns.current_user, socket, "")
      )
    }
  end


  def handle_event(
    "revert-todo-item-contact", 
    _data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply, just_edit_done(socket)}
  end


  @doc """
  WHen the input field or the datalist is blurred, we would like 
  to figure out, if the focus receive is one of input field or
  datalist's child, or if the user aborted the input operation.
  In the latter case, we'd like 
  """
  def handle_event(
    "blur-todo-item-contact", 
    data, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect(data)
    #if !String.starts_with?(data.relatedTarget, "input-todo-item-contact") do
      {:noreply, just_edit_done(socket)}
    #else
    #  {:noreply, socket}
    #end
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
      |> find_edit_done(:due, datetext)
    }
  end


  @impl true
  def handle_event(
    "validate-todo-item-due", 
    %{"_target" => _target, "duedate" => datetext}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect(["validate due", datetext])
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
