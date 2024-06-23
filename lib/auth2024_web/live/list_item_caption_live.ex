defmodule Auth2024Web.ListItemCaptionLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item,Person}
  alias Auth2024.Todos

  @topic "live"

  @impl true
  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end

  def empty_assigns() do
    %{
    is_list_item_caption_editing: false,
    list_item_editing_value: nil,
    list_item_editing_item: nil,
    }
  end


  def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    IO.inspect("list_item_just_edit_done")
    editing_item = socket.assigns.list_item_editing_item
    socket = socket 
    |> assign(empty_assigns())

    #|> assign(
    #  items: Todos.list_items(
    #    socket.assigns.user, 
    #    socket.assigns.filter_by_value,
    #    socket.assigns.sort_by_column
    #  )
    #)

    send( self(), %{ 
      event: socket.assigns.onitemchanged,
      item_id: editing_item
    } )

    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
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
    value
  ) do
    user = socket.assigns.user
    current_item = Todos.get_item!(socket.assigns.list_item_editing_item)
    Todos.update_item_caption(user, current_item, %{caption: value})
    socket |> just_edit_done()
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
    {
      :noreply,
      assign(socket,
        is_list_item_caption_editing: true,
        list_item_editing_value: data["text"],
        list_item_editing_item: String.to_integer(data["item_id"]),
      )
    }
  end


  def handle_event(
    "submit-todo-item-caption", 
    %{"item_id" => _item_id, "text" => text},
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply, save_edit_done(socket, text)}
  end


  @impl true
  def handle_event(
    "validate-todo-item-caption",
    %{"_target" => _target, "text" => text}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {
      :noreply,
      assign(socket,
        list_item_editing_value: text
      )
    }
  end


end