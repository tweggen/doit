defmodule Auth2024Web.EditTodoLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todo.{Item,Person}
  alias Auth2024.Todos

  @form_topic "edit_todo_live"


  def push_js(
    %Phoenix.LiveView.Socket{} = socket, to, js
  ) do
    event_details = %{
      to: to,
      encodedJS: Phoenix.json_library().encode!(js.ops)
    }
    socket |> Phoenix.LiveView.push_event("exec-js", event_details);
  end


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
      IO.inspect("have item")
      IO.inspect(item)

      caption = if item.caption==nil do ""  else item.caption end
      content = if item.content==nil do ""  else item.content end

      push_js(socket, root_id(form_name), 
        %JS{} 
        |> JS.set_attribute({"value", item_id}, to: "#edit_todo-id")
        |> JS.set_attribute({"value", caption}, to: "#edit_todo-caption")
        |> JS.set_attribute({"value", content}, to: "#edit_todo-content")
      )
    else
      IO.inspect("no item")
      socket
    end
    |> push_js(
      modal_id(form_name),
      Auth2024Web.CoreComponents.show_modal(modal_id(form_name))
    )
  end


  @impl true
  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end


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

  def update(assigns, socket) do
    { :ok,
      socket
      |> assign(assigns)
    }
  end
 @impl true

  def handle_event(
    "edit_todo-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"item" => item_params} = params
    user = socket.assigns.user
    item_id = String.to_integer(item_params["id"])
    caption = item_params["caption"]
    content = item_params["content"]

    IO.inspect(item_params)
    case Todos.update_item_caption_content(user, %Item{:id => item_id}, item_params) do
      {:error, message} ->
        { :noreply, 
          socket 
          |> assign(edit_todo_form_errors: [message])
        }

      {:ok, person} ->
        new_assigns = %{
          # TXWTODO: Optimize this by just merging in the new person
          edit_todo_form_errors: [],
          edit_todo_form: Phoenix.Component.to_form(Item.create_changeset(%{})),
        }

        send( self(), %{ 
          event: socket.assigns.onitem,
          changed_item_id: item_id
        } )

        { 
          :noreply, 
          socket 
          |> assign(new_assigns)
        }
    end
  end
end
