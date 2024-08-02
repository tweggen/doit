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
    content
  ) do
    if nil != content do
      push_js(socket, root_id(form_name), 
        %JS{} 
        |> JS.set_attribute({"value", content}, to: "#edit_todo-content")
      )
    else
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
        Phoenix.Component.to_form(Person.create_changeset(%{})),
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

end
