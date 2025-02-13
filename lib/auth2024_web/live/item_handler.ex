defmodule Auth2024Web.ItemHandler do
  @moduledoc false

  import Phoenix.Component, only: [assign: 2, assign: 3]
  import Phoenix.LiveView, only: [push_event: 3]
  
  alias Auth2024.Todo.{Item}
  alias Auth2024Web.ItemList


  @topic "page_live"

  @doc """
  Find associated data with the new value in the database or other
  sources, possibly cancelling the edit or opening a modal user flow.

  This function either terminates the flow or continues using a modal
  or calls save_edit_done.

  returns socket
  """
  defp find_edit_done(
    %Phoenix.LiveView.Socket{} = socket, 
    item_id,
    kind, 
    value
  ) do
    # user = socket.assigns.current_user
    # current_item = Todos.get_item!(socket.assigns.editing_item)
    case kind do
      :due ->
        socket |> PageLive.save_edit_done(item_id, kind, value)
    end
  end


  def submit_todo_item_due(
        %{"item_id" => item_id, "duedate" => datetext},
        %Phoenix.LiveView.Socket{} = socket
      ) do
    IO.inspect("Called submit-todo-item-due")
    {
      :noreply,
      socket
      |> assign(editing_item: item_id)
      |> find_edit_done(item_id, :due, datetext)
    }
  end
  

  @impl true
  def create(
        %{"text" => text},
        %Phoenix.LiveView.Socket{} = socket
      ) do
    case Todos.add_item(socket.assigns.current_user, ItemList.default_editing_item_values(socket, text)) do
      {:ok, item} ->
        {:noreply,
          socket
          |> Tools.open_edit_item(item.id, :content)
        }
      _ ->
        socket
        |> ItemList.query_items()
        |> assign(
             active: %Item{}
           )
        Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
        {:noreply, socket}
    end
  end


  @impl true
  def delete(
        data,
        %Phoenix.LiveView.Socket{} = socket
      ) do
    user = socket.assigns.current_user
    Todos.delete_item(user, Map.get(data, "item_id"))
    socket = socket
             |> ItemList.query_items()
             |> assign(
                  active: %Item{}
                )
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end


  @impl true
  def toggle(data, socket) do
    user = socket.assigns.current_user
    status = if Map.has_key?(data, "value"), do: 1, else: 0
    item = Todos.get_item!(Map.get(data, "item_id"))
    Todos.update_item(user, item, %{status: status})
    socket = socket
             |> ItemList.query_items()
             |> assign(
                  active: %Item{}
                )
    Auth2024Web.Endpoint.broadcast(@topic, "update", socket.assigns)
    {:noreply, socket}
  end
  
end
