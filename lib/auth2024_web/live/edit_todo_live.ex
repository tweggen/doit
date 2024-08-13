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
    %Item{} = item
  ) do
    IO.inspect("show1")
    IO.inspect(item)

    if nil != item do

      IO.inspect("show2")

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
          IO.inspect("have hydrated item")
          IO.inspect(tmp.item)
          tmp
        else
          tmp = %{
            :item => nil,
            :caption => "",
            :content => "",
            :contact_id => -1,
            :due => Timex.format!(:calendar.local_time(), "{YYYY}-{0M}-{0D}")
          }
          IO.inspect("have a new item")
          IO.inspect(tmp.item)
          tmp
        end

      IO.inspect("show3")

      socket
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
    else
      IO.inspect("no item")
      socket
    end

    |> Tools.push_js(
      modal_id(@form_name_edit_item),
      Auth2024Web.CoreComponents.show_modal(modal_id(@form_name_edit_item))
    )
  end


  def terminate(reason, state) do
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
    "edit_todo-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"item" => item_params, "contact_person_id" => contact_id_string} = params

    user = socket.assigns.current_user
    item_id = String.to_integer(item_params["id"])
    #caption = item_params["caption"]
    #content = item_params["content"]
    contact_id = String.to_integer(contact_id_string)
    #due = item_params["due"]
    contact_person = Todos.get_person!(contact_id)

    case Todos.update_item(user, %Item{:id => item_id}, item_params) do
      {:error, message} ->
        IO.inspect("update error 1")
        { :noreply, 
          socket 
          |> assign(edit_todo_form_errors: [message])
        }

      {:ok, item} ->
        case Todos.update_item_contact(user, item, %{:contact => contact_person}) do
          {:error, message} ->
            IO.inspect("update error 2")
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
