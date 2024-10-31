defmodule Auth2024Web.ListItemPersonLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todos

  @form_name_new_person "confirm-new-person"


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
    socket = socket 
    |> assign(empty_assigns())
    socket
  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:ok, socket |> assign(empty_assigns())}
  end


  @impl true
  def update(assigns, socket) do
    { :ok,
      socket
      |> assign(assigns)
    }
  end


  def save_edit_done(
    %Phoenix.LiveView.Socket{} = socket,
    kind,
    value
  ) do
    user = socket.assigns.user
    item_id = socket.assigns.list_item_person_editing_item
    current_item = Todos.get_item!(item_id)
    Todos.update_item_contact(user, current_item, %{kind => value})

    if socket.assigns.onitemchanged != nil do
      send( self(), %{ 
        event: socket.assigns.onitemchanged,
        item_id: item_id,
        kind: kind,
        value: value
      } )
    end
    socket |> just_edit_done()
  end


  defp possibly_update_item_contact(
    %Phoenix.LiveView.Socket{} = socket, 
    _item_id,
    contact_person_id
  ) do
    contact_person = Todos.get_person!(contact_person_id)
    
    if contact_person != nil do
      socket |> save_edit_done(socket.assigns.kind, contact_person)
    else
      socket 
      |> Auth2024Web.ConfirmNewPersonLive.show(
        @form_name_new_person, 
        contact_person_id,
        "confirm_new_person_onperson"
      )
    end
  end


  @impl true
  def handle_event(
    "submit-todo-item-contact", 
    %{"item_id" => item_id, "contact_person_id" => contact_person_id}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect("submit-todo-item-contact called.")
    if nil != socket.assigns.onediting do
      send( self(), %{ 
        event: socket.assigns.onediting,
        item_id: item_id,
      } )
    end

    if socket.assigns.kind != nil do
      socket = socket |> assign(list_item_person_editing_item: item_id)
      if String.ends_with?(contact_person_id, "-create-new") do
        {:noreply, 
          socket 
          |> Auth2024Web.ConfirmNewPersonLive.show(
            @form_name_new_person, 
            nil,
            "confirm_new_person_onperson"
          )
        }
      else
        {
          :noreply, 
          socket 
          |> possibly_update_item_contact(item_id, contact_person_id)
        }
      end
    else
      { :noreply, socket }
    end
  end



end