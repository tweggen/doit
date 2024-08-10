defmodule Auth2024Web.EditTodoLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item}
  alias Auth2024.Todos
  alias Auth2024Web.Tools


  defp root_id(name) do
    "edit_todo_top-#{name}"
  end


  defp modal_id(name) do
    "edit_todo_modal-#{name}"
  end


  def show(
    socket, 
    form_name, 
    item_id,
    item
  ) do
    if nil != item do

      item = Todos.hydrate_item(item)

      IO.inspect("have hydrated item")
      IO.inspect(item)

      caption = if item.caption==nil do ""  else item.caption end
      content = if item.content==nil do ""  else item.content end
      contact_id = item.contact.id
      due = Tools.display_due_date(item.due)

      socket
      |> push_event("set-value", %{id: "edit_todo-content", value: content})
      
      |> push_event("set-value", %{id: "select-todo-item-contact-in_edit_todo_modal", value: contact_id})
      |> Tools.push_js(root_id(form_name), 
        %JS{} 
        |> JS.set_attribute({"value", item_id}, to: "#edit_todo-id")
        |> JS.set_attribute({"value", caption}, to: "#edit_todo-caption")
        |> JS.set_attribute({"value", due}, to: "#edit_todo-due")
      )
    else
      IO.inspect("no item")
      socket
    end

    |> Tools.push_js(
      modal_id(form_name),
      Auth2024Web.CoreComponents.show_modal(modal_id(form_name))
    )
  end


  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end


  def handle_info(
    %{event: "on_edittodo_contact_changed", item_id: item_id, kind: kind, value: value},
    socket
  ) do
    IO.inspect(value)
    {
      :noreply,
      socket
    }
  end


  @impl true
  def handle_event(
    "edit_todo-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"item" => item_params, "contact_person_id" => contact_id_string} = params

    IO.inspect("item_params are")
    IO.inspect(item_params)

    user = socket.assigns.current_user
    item_id = String.to_integer(item_params["id"])
    caption = item_params["caption"]
    content = item_params["content"]
    contact_id = String.to_integer(contact_id_string)
    due = item_params["due"]
    contact_person = Todos.get_person!(contact_id)

    case Todos.update_item(user, %Item{:id => item_id}, item_params) do
      {:error, message} ->
        { :noreply, 
          socket 
          |> assign(edit_todo_form_errors: [message])
        }

      {:ok, item} ->
        case Todos.update_item_contact(user, item, %{:contact => contact_person}) do
          {:error, message} ->
            { :noreply, 
              socket 
              |> assign(edit_todo_form_errors: [message])
            }

          {:ok, item} ->
            new_assigns = %{
              # TXWTODO: Optimize this by just merging in the new person
              edit_todo_form_errors: [],
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
              |> assign(new_assigns)
            }
      end
    end
  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{
      create_edit_todo_form: nil,
      edit_todo_form: 
        Phoenix.Component.to_form(Item.create_changeset(%{})),
      edit_todo_form_errors: []
    }
    {:ok, socket |> assign(default_assigns)}
  end


  @impl true
  def update(assigns, socket) do
    { :ok,
      socket
      |> assign(assigns)
    }
  end

end
