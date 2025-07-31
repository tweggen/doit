defmodule Auth2024Web.ListItemCaptionLive do
  use Auth2024Web, :live_component

  alias Auth2024.Todos
  alias Auth2024Web.Tools



  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end

  def empty_assigns() do
    %{
    is_list_item_caption_editing: false,
    list_item_caption_editing_value: nil,
    list_item_caption_editing_item: nil,
    }
  end


  def cancel_edit_item(%Phoenix.LiveView.Socket{} = socket) do
    IO.inspect("list_item_caption_cancel_edit_item")
    socket |> assign(empty_assigns())
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


  @doc """
  Finalize the editing by saving the data to the databse.
  """
  def save_edit_done(
    %Phoenix.LiveView.Socket{} = socket,
    value
  ) do
    #user = socket.assigns.user
    #current_item = Todos.get_item!(socket.assigns.list_item_caption_editing_item)

    # Send the change to the parent live view
    send( self(), %{ 
      event: socket.assigns.onitemchanged,
      item_id: socket.assigns.list_item_caption_editing_item,
      kind: :caption,
      value: value
    } )

    socket |> cancel_edit_item()
  end


  defp edit_item_caption(
    %Phoenix.LiveView.Socket{} = socket,
    data
  ) do
    assign(socket,
      is_list_item_caption_editing: true,
      list_item_caption_editing_value: data["text"],
      list_item_caption_editing_item: String.to_integer(data["item_id"])
    )
  end


  @impl true
  def handle_event(
    "click-item",
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
        list_item_caption_editing_value: text
      )
    }
  end
end
