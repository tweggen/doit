defmodule Auth2024Web.PageLive do
  use Auth2024Web, :live_view
  alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item}
  alias Auth2024.Todos
  alias Auth2024Web.ItemList
  alias Auth2024Web.Tools

  alias Auth2024Web.ItemHandler
  
  @topic "page_live"

  @impl true
  def terminate(reason, _state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    # IO.inspect({:state, state})
  end

  
  @impl true
  def handle_event("submit-todo-item-due", params, socket), do: ItemHandler.submit_todo_item_due(params, socket)
  def handle_event("create", params, socket), do: ItemHandler.create(params, socket)
  def handle_event("delete", params, socket), do: ItemHandler.delete(params, socket)
  def handle_event("toggle", params, socket), do: ItemHandler.toggle(params, socket)

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


  defp default_assigns() do
    %{
      editing_item: nil,
      editing_kind: nil,
      current_user: nil,
      current_item: nil,
      current_person: nil,
      editing_item_datalist: [],
      items: nil,
      percent_late: 0,
      available_persons: [],
      solo_contact: nil
    }
  end


  @impl true
  def mount(
    _params, session, %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = default_assigns()

    socket = Auth2024Web.Tools.assign_session_id(socket, session)

    # subscribe to the channel
    if connected?(socket) do
      Auth2024Web.Endpoint.subscribe(@topic)
      Auth2024Web.ConfirmNewPersonLive.subscribe(socket, "page-confirm_new_person")
    end

    with token when is_bitstring(token) <- session["user_token"], user when not is_nil(user) <- Auth2024.Accounts.get_user_by_session_token(token) do
      current_person = Todos.find_person_for_user(user)
      user_config = Todos.find_config_for_user(user)
      {:ok, 
        socket 
        |> assign(default_assigns) 
        |> assign(
            current_session: session,
            user_config: user_config,
            current_user: user,
            current_person: current_person,
            available_persons: editing_contact_datalist(user, socket, ""),
            editing_item_values: empty_editing_item_values()
        )
        |> ItemList.query_items()
      }
    else
      _ -> {:ok, socket}
    end
  end


 def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    socket = socket 
      |> ItemList.query_items()
      |> assign(
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


  # TXWTODO: A proper validation path is missing, we are directly going into the
  # save path, treating validation as a special case.


  def handle_event(
    "submit-todo-contact-due", 
    %{"contact_id" => contact_id, "duedate" => datetext}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    user = socket.assigns.current_user
    Todos.update_person_due(user, contact_id, datetext)
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {
      :noreply,
      socket 
      |> ItemList.query_items()
    }
  end


  def handle_event(
    "on-solo-click",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    socket =
      case Todos.config_sort_by_column(socket.assigns.user_config) do
        "date" -> socket
        "contact" ->
          assign(socket, 
            solo_contact: 
              case socket.assigns.solo_contact do
                nil -> params["header"]
                _ -> nil          
              end
          ) 
      end
    {:noreply, socket}
  end


  def handle_event(
    "on-header-click",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    socket = socket |> Auth2024Web.EditTodoLive.show(
      -1,
      case Todos.config_sort_by_column(socket.assigns.user_config) do
        "date" ->
          %Item{:due => params["header"]}
        "contact" ->
          %Item{:contact_id => params["header"]}
      end,
      :caption
    )
    {:noreply, socket}
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
    if connected?(socket) do
      user = socket.assigns.current_user

      user_config = socket.assigns.user_config

      current_filter_by_value = Todos.config_filter_by_value(user_config)
      new_filter_by_value = if Map.has_key?(params, "filter_by") do params["filter_by"] else current_filter_by_value end
      current_sort_by_column = Todos.config_sort_by_column(user_config)
      new_sort_by_column = if Map.has_key?(params, "sort_by") do params["sort_by"] else current_sort_by_column end

      user_config = 
        if current_filter_by_value != new_filter_by_value || current_sort_by_column != new_sort_by_column do
          new_config_properties = Map.merge(user_config.properties, %{
            "filterByValue" => new_filter_by_value, 
            "sortByColumn" => new_sort_by_column
          })
          case Todos.update_config(user, user_config, %{"properties" => new_config_properties}) do
            {:ok, written_config} -> written_config
            _ -> user_config
          end
        else
          user_config
        end

      {:noreply,
        assign(socket,
          user_config: user_config,
          items: Todos.list_items(user, new_filter_by_value, nil, new_sort_by_column)
        )
      }
    else
      {:noreply, socket}
    end
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
    #socket
    {
      :noreply,
      socket
      |> save_edit_done(socket.assigns.editing_item, :contact, person)
      |> assign(new_assigns)
    }
  end


  def handle_info(
    %{event: "page-confirm_new_person", confirmed_person: _person},
    socket
  ) do
    #socket
    {
      :noreply,
      socket
      |> just_edit_done()
    }
  end


  def handle_info(
    %{event: "edit_todo_onitem", changed_item: _item},
    socket
  ) do
    #socket
    {
      :noreply,
      socket
      |> just_edit_done()
    }
  end


  @impl true
  def handle_event(
    "edit-item-by-caption",
    data,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    item_id = String.to_integer(data["item_id"])
    {
      :noreply,
      socket
      |> Tools.open_edit_item(item_id, :caption)
    }
  end


  @impl true
  def handle_event(
    "edit-item-by-contact",
    data,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    item_id = String.to_integer(data["item_id"])
    {
      :noreply,
      socket
      |> Tools.open_edit_item(item_id, :contact)
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


  def form_todo_contact_due_id(contact) do
    "form-todo-contact-due-#{contact.id}"
  end

end
