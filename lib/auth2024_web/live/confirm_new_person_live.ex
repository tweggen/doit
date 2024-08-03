defmodule Auth2024Web.ConfirmNewPersonLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todos
  alias Auth2024.Todo.Person


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
    "confirm_new_person_top-#{name}"
  end


  defp modal_id(name) do
    "confirm_new_person_modal-#{name}"
  end


  def show(
    socket, 
    form_name, 
    _item_id,
    family_name
  ) do
    if nil != family_name do
      push_js(socket, root_id(form_name), 
        %JS{} 
        |> JS.set_attribute({"value", family_name}, to: "#new-person-form-family-name")
      )
    else
      socket
    end
    |> push_js(
      modal_id(form_name),
      Auth2024Web.CoreComponents.show_modal(modal_id(form_name))
    )
  end


  def terminate(reason, state) do
    IO.inspect("terminate/2 callback")
    IO.inspect({:reason, reason})
    IO.inspect({:state, state})
  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{
      create_confirm_new_person_form: nil,
      new_person_form: 
        Phoenix.Component.to_form(Person.create_changeset(%{})),
      new_person_form_errors: []
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
 

  @impl true
  def handle_event(
    "create-new-person-submit",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    # Inform the view that this is the currently editing item

    %{"person" => person_params} = params
    user = socket.assigns.user
    family_name = person_params["family_name"]
    given_name = person_params["given_name"]

    similarily_named_person = Todos.search_person_by_name(
      family_name, given_name)

    if [] != similarily_named_person do
      { :noreply, 
        socket 
        |> assign(new_person_form_errors: ["Person with similar name already exists."])
      }
    else
      case Todos.add_person(user, Map.merge(person_params, %{"status" => 0})) do
        {:error, message} ->
          { :noreply, 
            socket 
            |> assign(new_person_form_errors: [message])
          }

        {:ok, person} ->
          new_assigns = %{
            # TXWTODO: Optimize this by just merging in the new person
            new_person_form_errors: [],
            new_person_form: Phoenix.Component.to_form(Person.create_changeset(%{})),
          }

          send( self(), %{ 
            event: socket.assigns.onperson,
            confirmed_person: person
          } )

          { 
            :noreply, 
            socket 
            |> assign(new_assigns)
          }
      end
    end
  end


end
