defmodule Auth2024Web.PersonsLive do
  use Auth2024Web, :live_view
  alias Auth2024.Todos
  alias Auth2024.Todos.Persons
  alias Auth2024Web.Tools
 
  @topic "person_live"


  defp default_assigns() do
    %{}
  end


  def cancel_edit_item(%Phoenix.LiveView.Socket{} = socket) do
    socket = socket 
      |> assign(
      persons: Todos.list_persons!(
        socket.assigns.current_user
        #  ,default_assigns.filter_by_value
        #  ,default_assigns.sort_by_column
        )
     )
    Auth2024Web.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    socket
  end


  def open_edit_person(
    %Phoenix.LiveView.Socket{} = socket,
    data
  ) do
    person_id = String.to_integer(data["person_id"])
    current_person = Todos.get_person!(person_id)

    IO.inspect("opening edit person for")
    IO.inspect(person_id)
    IO.inspect(current_person)
    socket 
    |> Auth2024Web.EditPersonLive.show(
      person_id,
      current_person
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
      socket
      |> open_edit_person(data)
    }
  end


  @impl true
  def handle_info(
    %{event: "edit_person_onperson", changed_person: _person},
    socket
  ) do
    {
      :noreply,
      socket
      |> cancel_edit_item()
    }
  end


  @impl true
  def handle_info(
    %{event: "update", payload: %{persons: persons}}, 
    %Phoenix.LiveView.Socket{} = socket
  ) do
    {:noreply, assign(socket, persons: persons)}
  end


  @impl true
  def mount(
    _params, session, %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = default_assigns()
    # subscribe to the channel
    if connected?(socket), do: Auth2024Web.Endpoint.subscribe(@topic)
    with token when is_bitstring(token) <- session["user_token"],
      user when not is_nil(user) <- Auth2024.Accounts.get_user_by_session_token(token) do
        current_person = Todos.find_person_for_user(user)
        persons = Todos.list_persons!(
           user
        #  ,default_assigns.filter_by_value
        #  ,default_assigns.sort_by_column
        )
      #IO.inspect(persons)
      {:ok, 
        socket 
        |> assign(default_assigns) 
        |> assign(
            current_user: user,
            current_person: current_person,
            persons: persons
        #    available_persons: editing_contact_datalist(user, socket, ""),
        #    editing_item_values: empty_editing_item_values()
        )
      }
    else
      _ -> {:ok, socket}
    end
  end


end