defmodule Auth2024Web.ListItemPersonLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item,Person}
  alias Auth2024.Todos

  @topic "live"


  @form_name_new_person "confirm-new-person"


  @impl true
  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end

  def empty_assigns() do
    %{
    is_list_item_person_editing: false,
    list_item_person_editing_item: nil,
    }
  end


  def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    IO.inspect("list_item_person_just_edit_done")
    socket = socket 
    |> assign(empty_assigns())
    socket
  end


  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:ok, socket |> assign(empty_assigns())}
  end


  def update(assigns, socket) do
    { :ok,
      socket
      |> assign(assigns)
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


  @doc """
  Finalize the editing by saving the data to the databse.
  """
  def save_edit_done(
    %Phoenix.LiveView.Socket{} = socket,
    kind,
    value
  ) do
    user = socket.assigns.user
    item_id = socket.assigns.list_item_person_editing_item
    current_item = Todos.get_item!(item_id)
    Todos.update_item_contact(user, current_item, %{kind => value})

    send( self(), %{ 
      event: socket.assigns.onitemchanged,
      item_id: item_id,
      kind: :contact,
      value: value
    } )

    socket |> just_edit_done()
  end


  defp possibly_update_item_contact(
    %Phoenix.LiveView.Socket{} = socket, 
    item_id,
    contact_person_name
  ) do
    contact_person = Todos.search_person_family_name(contact_person_name)
    IO.inspect(["contact person", contact_person_name, contact_person])
    
    if contact_person != nil do
      IO.inspect(contact_person)
      socket |> save_edit_done(:contact, contact_person)
    else
      socket 
      |> Auth2024Web.ConfirmNewPersonLive.show(
        @form_name_new_person, 
        item_id,
        contact_person_name
      )
    end
  end


  def handle_event(
    "submit-todo-item-contact", 
    %{"item_id" => item_id, "contact_person_name" => contact_person_name}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    send( self(), %{ 
      event: socket.assigns.onediting,
      item_id: item_id
    } )

    socket = socket |> assign(list_item_person_editing_item: item_id)
    if contact_person_name == "Create new..." do
      {:noreply, 
        socket 
        |> Auth2024Web.ConfirmNewPersonLive.show(
          @form_name_new_person, 
          item_id,
          nil
        )
      }
    else
      {
        :noreply, 
        socket 
        |> possibly_update_item_contact(item_id, contact_person_name)
      }
      end
  end


end