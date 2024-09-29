defmodule Auth2024Web.ConfirmNewPersonLive do
  use Auth2024Web, :live_component

  #alias Phoenix.LiveView.JS
  alias Auth2024.Todos
  alias Auth2024.Todo.Person
  alias Auth2024Web.Tools


  defp root_id(name) do
    "confirm_new_person_top-#{name}"
  end


  defp modal_id(name) do
    "confirm_new_person_modal-#{name}"
  end


  def show(
    socket, 
    form_name, 
    family_name
  ) do
    if nil != family_name do
      Tools.push_js(socket, root_id(form_name), 
        %JS{} 
        |> JS.remove_attribute("value", to: "#new-person-form-family-name")
        |> JS.set_attribute({"value", family_name}, to: "#new-person-form-family-name")
      )
      |> push_event("set-value", %{id: "new-person-form-family-name", value: family_name})
    else
      socket
    end
    |> Tools.push_js(
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
        Phoenix.Component.to_form(Person.create_changeset(%{}, nil)),
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
    email = person_params["email"]

    similarily_named_person = Todos.search_person_by_name(
      user, family_name, given_name)
    person_with_email = Todos.search_person_by_email(
      user, email)

    if [] != similarily_named_person ||  [] != person_with_email do
      { :noreply, 
        socket 
        |> assign(new_person_form_errors: ["Person with similar name or email already exists."])
      }
    else
      all_person_params = Map.merge(person_params, %{"status" => 0, "owning_user_id" => user.id})
      case Todos.add_person(user, all_person_params) do
        {:error, message} ->
          { :noreply, 
            socket 
            |> assign(new_person_form_errors: [message])
          }

        {:ok, person} ->
          new_assigns = %{
            # TXWTODO: Optimize this by just merging in the new person
            new_person_form_errors: [],
            new_person_form: Phoenix.Component.to_form(Person.create_changeset(%{}, user.id)),
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
