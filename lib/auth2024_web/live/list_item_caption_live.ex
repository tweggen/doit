defmodule Auth2024Web.ListItemCaptionLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item,Person}
  alias Auth2024.Todos

  @topic "live"
  @form_name_edit_item "edit-todo"

  @impl true
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


  def just_edit_done(%Phoenix.LiveView.Socket{} = socket) do
    IO.inspect("list_item_caption_just_edit_done")
    socket |> assign(empty_assigns())
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
    #user = socket.assigns.user
    #current_item = Todos.get_item!(socket.assigns.list_item_caption_editing_item)

    # Send the change to the parent live view
    send( self(), %{ 
      event: socket.assigns.onitemchanged,
      item_id: socket.assigns.list_item_caption_editing_item,
      kind: :caption,
      value: value
    } )

    socket |> just_edit_done()
  end


  @doc """
  Open the item editing dialogue
  (if configured to open modally)
  """
  @impl true
  def open_edit_item(
    %Phoenix.LiveView.Socket{} = socket,
    data
  ) do
    item_id = String.to_integer(data["item_id"])
    current_item = Todos.get_item!(item_id)

    socket 
    |> Auth2024Web.EditTodoLive.show(
      @form_name_edit_item, 
      item_id,
      current_item
    )
  end


  @doc """
  Activates editing the item's caption.
  (if configured to open in place)
  """
  @impl true
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
    {
      :noreply,
      if false do
        socket 
        |> edit_item_caption(data)
      else
        socket
        |> open_edit_item(data)
      end
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
