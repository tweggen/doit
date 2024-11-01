defmodule Auth2024Web.EditTodoLive do
  use Auth2024Web, :live_component

  alias Auth2024.Todo.{Item}
  alias Auth2024.Todos
  alias Auth2024Web.Tools


  defp root_id(name) do
    "edit_todo_top-#{name}"
  end


  defp modal_id(name) do
    "edit_todo_modal-#{name}"
  end

  @form_name_edit_item "edit-todo"

  def show(
    %Phoenix.LiveView.Socket{} = socket, 
    item_id,
    %Item{} = item,
    focus_field
  ) do
    if nil != item do
      template = 
        if Map.has_key?(item, :id) && item.id != nil && item.id != -1 do
          hydrated_item = Todos.hydrate_item(item)
          tmp = %{
            :item => Todos.hydrate_item(hydrated_item),
            :caption => Tools.display_string(hydrated_item.caption),
            :content => Tools.display_string(hydrated_item.content),
            :contact_id => hydrated_item.contact.id,
            :due => hydrated_item.due
          }
          tmp
        else
          IO.inspect(item)
          tmp = %{
            :item => nil,
            :caption => Tools.display_string(item && Map.get(item, :caption, nil)),
            :content => Tools.display_string(item && Map.get(item, :content, nil)),
            :contact_id => item && Map.get(item, :contact_id, nil) || socket.assigns.current_user.id,
            :due => item && Map.get(item, :due, nil) || Timex.format!(:calendar.local_time(), "{YYYY}-{0M}-{0D}")
          }
          IO.inspect(tmp)
          tmp
        end

      socket
      # |> assign(%{template: template})
      |> push_event("set-value", %{id: "edit_todo-content", value: template.content})
      |> push_event("set-value", %{id: "select-todo-item-contact-in_edit_todo_modal", value: template.contact_id})
      |> Tools.push_js(root_id(@form_name_edit_item), 
        %JS{} 
        |> JS.remove_attribute("value", to: "#edit_todo-id") 
        |> JS.set_attribute({"value", item_id}, to: "#edit_todo-id")
        |> JS.remove_attribute("value", to: "#edit_todo-caption") 
        |> JS.set_attribute({"value", template.caption}, to: "#edit_todo-caption")
        |> JS.remove_attribute("value", to: "#edit_todo-due") 
        |> JS.set_attribute({"value", template.due}, to: "#edit_todo-due")
      )
      |> push_event("set-value", %{id: "edit_todo-id", value: item_id})
      |> push_event("set-value", %{id: "edit_todo-caption", value: template.caption})
      |> push_event("set-value", %{id: "edit_todo-due", value: template.due})
    else
      socket
    end

    # We need to focus only after we show.
    |> Tools.push_js(
      modal_id(@form_name_edit_item),
      Auth2024Web.CoreComponents.show_modal(modal_id(@form_name_edit_item))
      |> JS.focus(to: 
        case focus_field do
          :caption -> "#edit_todo-caption"
          :contact -> "#select-todo-item-contact-in_edit_todo_modal"
          _ -> "#edit_todo-content"
        end
      )
    )
  end


  def terminate(reason, _state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    # IO.inspect({:state, state})
  end


  def handle_info(
    %{event: "on_edittodo_contact_changed", item_id: _item_id, kind: _kind, value: value},
    socket
  ) do
    {
      :noreply,
      socket
    }
  end


  @impl true
  def handle_event(
    "edit_todo-new_person",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect("clicked")
    socket =
    if socket.assigns.is_new_person_open do
      Tools.push_js(socket, root_id(@form_name_edit_item), 
        %JS{} 
        |> JS.hide(
          to: "#edit_todo-new_person_container",
          #transition:  {
          #  "ease-out duration-300",
          #  "opacity-100", "opacity-0"
          #}
        )
        |> JS.show(
          to: "#edit_todo-existing_person_container",
          #transition:  {
          #  "ease-out duration-300",
          #  "opacity-0", "opacity-100"
          #}
        )
      )
      |> assign(%{is_new_person_open: false})
    else
      Tools.push_js(socket, root_id(@form_name_edit_item), 
        %JS{} 
        |> JS.hide(
          to: "#edit_todo-existing_person_container",
          #transition:  {
          #  "ease-out duration-300",
          #  "opacity-100", "opacity-0"
          #}
        )
        |> JS.show(
          to: "#edit_todo-new_person_container",
          #transition:  {
          #  "ease-out duration-300",
          #  "opacity-0", "opacity-100"
          #}
        )
      )
      |> assign(%{is_new_person_open: true})
      #|> push_event("set-value", %{id: "new-person-form-family-name", value: family_name})
      #|> push_event("set-value", %{id: "new-person-form-submit-event", value: onsubmit})
    end

    {
      :noreply, 
      socket 
    }
  end


  @impl true 
  def handle_event(
    "edit_todo-new_person_selected",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {
      :noreply,
      socket
    }
  end


  defp add_or_update_item(user, item_id, params) do
    if -1 == item_id do
      Todos.add_item(user, params)
    else
      Todos.update_item(user, %Item{:id => item_id}, params)
    end
  end


  defp handle_fetch_or_create_person_then(
    %Phoenix.LiveView.Socket{} = socket,
    params, contact_id,
    f_person
  ) do
    user = socket.assigns.current_user
    should_create_new_person = socket.assigns.is_new_person_open

    case should_create_new_person do
      true -> 
        IO.inspect("about to create new person")
        family_name = params["family_name"]
        given_name = params["given_name"]
        email = params["email"]    
        case Todos.possibly_add_person(user, email, family_name, given_name) do
          { -1, message } ->
            {
              :noreply,
              socket
              |> assign(edit_todo_form_errors: [message])
            }
          
          { new_person_id, new_person } ->
            f_person.(new_person)
        end
      false -> 
        IO.inspect("about to use existing person")
        f_person.(Todos.get_person!(contact_id))
    end
  end


  defp handle_add_update_item(
    %Phoenix.LiveView.Socket{} = socket,
    item_id,
    add_update_params, person
  ) do
    user = socket.assigns.current_user
    # Now, depending on wether it is a new item we shall create or an
    # existing we shall update, perform the database access.

    # add the person passed to us.
    add_update_params = Map.put(add_update_params, "contact_person", person)
    case add_or_update_item(user, item_id, add_update_params) do
      {:error, message} ->
        IO.inspect("add error 1")
        { :noreply, 
          socket 
          |> assign(edit_todo_form_errors: [message])
        }

      {:ok, item} ->
        case Todos.update_item_contact(user, item, %{:contact => person}) do
          {:error, message} ->
    
            IO.inspect("add error 2")
            IO.inspect(message)
            { :noreply, 
              socket 
              |> assign(edit_todo_form_errors: [message])
            }

          {:ok, item} ->
            new_assigns = %{
              # TXWTODO: Optimize this by just merging in the new person
              edit_todo_form_errors: [],
              form_name: nil,
              edit_todo_form: Phoenix.Component.to_form(Item.create_changeset(%{})),
            }

            if nil != socket.assigns.onitem do
              send( self(), %{ 
                event: socket.assigns.onitem,
                changed_item: item
              } )
            end

            { 
              :noreply, 
              socket 
              |> push_event("close_modal",  %{to: "##{modal_id(@form_name_edit_item)}"})
              |> assign(new_assigns)
            }
        end
      
    end
  end


  @impl true
  def handle_event(
    "edit_todo-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"item" => item_params, "contact_person_id" => contact_id_string} = params

    IO.inspect(params)
    user = socket.assigns.current_user
    current_person = Todos.find_person_for_user(user)
    item_id = String.to_integer(item_params["id"])
    contact_id = String.to_integer(contact_id_string)
    {:ok, due_date } = Date.from_iso8601(item_params["due"])

    add_update_params = 
      if -1 == item_id do
        IO.inspect("About to create new item")
        %{
          "status" => 0,
          "author" => current_person,
          "content" => item_params["content"],
          "caption" => item_params["caption"],
          "due" => due_date
        }
      else
        IO.inspect("About to update item")
        item_params
      end

    handle_fetch_or_create_person_then(socket, add_update_params, contact_id,
      fn person -> handle_add_update_item(socket, item_id, add_update_params, person) end)

  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{
      create_edit_todo_form: nil,
      edit_todo_form: Phoenix.Component.to_form(Item.create_changeset(%{})),
      edit_todo_form_errors: [],
      is_new_person_open: false
    }

    socket = socket 
    |> assign(default_assigns)

    {:ok, socket}
  end


  @impl true
  def update(assigns, socket) do

    had_session_id_before = Map.has_key?(assigns, :session_id)
    socket = socket
    |> assign(assigns)
    |> Auth2024Web.Tools.assign_session_id(assigns.session)
 
    if !had_session_id_before do
      Auth2024Web.ConfirmNewPersonLive.subscribe(socket, "edit_todo-confirm_new_person")
    end

    { :ok,
      socket
    }
  end


  def handle_info(
    %{event: "edit_todo-confirm_new_person", confirmed_person: person},
    socket
  ) do
    IO.inspect("Called edit_todo-confirm_new_person")
    IO.inspect(person)
    new_assigns = %{
      available_persons: Todos.list_persons!(socket.assigns.current_user),
    }
    #socket
    {
      :noreply,
      socket
      |> assign(new_assigns)
    }
  end


end
