defmodule Auth2024Web.EditPersonLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todos
  alias Auth2024.Todo.{Person}
  alias Auth2024Web.Tools

  defp root_id() do
    "edit_person_top"
  end


  defp modal_id() do
    "edit_person_modal"
  end


  def show(
    socket, 
    person_id,
    person
  ) do
    if nil != person do

      # load the user if there is one
      person = Todos.hydrate_person(person)

      family_name = Tools.display_string(person.family_name)
      given_name = Tools.display_string(person.given_name)
      email = Tools.display_string(person.email)

      socket
      |> Tools.push_js(root_id(), 
        %JS{} 
        |> JS.remove_attribute("value", to: "#edit_person-id") 
        |> JS.set_attribute({"value", person_id}, to: "#edit_person-id")
        |> JS.remove_attribute("value", to: "#edit_person-family_name") 
        |> JS.set_attribute({"value", family_name}, to: "#edit_person-family_name")
        |> JS.remove_attribute("value", to: "#edit_person-given_name") 
        |> JS.set_attribute({"value", given_name}, to: "#edit_person-given_name")
        |> JS.remove_attribute("value", to: "#edit_person-email") 
        |> JS.set_attribute({"value", email}, to: "#edit_person-email")
      )
      |> push_event("set-value", %{id: "edit_person-id", value: person_id})
      |> push_event("set-value", %{id: "edit_person-family_name", value: family_name})
      |> push_event("set-value", %{id: "edit_person-given_name", value: given_name})
      |> push_event("set-value", %{id: "edit_person-email", value: email})
    else
      IO.inspect("nil person")
      socket
    end

    |> Tools.push_js(
      modal_id(),
      Auth2024Web.CoreComponents.show_modal(modal_id())
    )
  end


  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end


  @impl true
  def handle_event(
    "edit_person-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"person" => person_params} = params

    user = socket.assigns.current_user
    person_id = String.to_integer(person_params["id"])

    case Todos.update_person(user, %Person{:id => person_id}, person_params) do
      {:error, message} ->
        { :noreply, 
          socket 
          |> assign(edit_person_form_errors: [message])
        }

      {:ok, person} ->
        new_assigns = %{
          # TXWTODO: Optimize this by just merging in the new person
          edit_person_form_errors: [],
          edit_person_form: Phoenix.Component.to_form(Person.create_changeset(%{}, nil)),
        }

        if nil != socket.assigns.onperson do
          send( self(), %{ 
            event: socket.assigns.onperson,
            changed_person: person
          } )
        end

        { 
          :noreply, 
          socket 
          |> push_event("close_modal",  %{to: "##{modal_id()}"})
          |> assign(new_assigns)
        }
    end
  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{
      create_edit_person_form: nil,
      edit_person_form: Phoenix.Component.to_form(Person.create_changeset(%{}, nil)),
      edit_person_form_errors: []
    }
    {
      :ok,
      socket 
      |> assign(default_assigns)
    }
  end


  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

end
