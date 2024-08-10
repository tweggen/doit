defmodule Auth2024Web.SelectPersonComponent do
  use Auth2024Web, :live_component
  alias Auth2024Web.Tools

  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  #use Phoenix.LiveComponent

  attr :autosubmit_to, :string, default: nil
  attr :autosubmit_id, :string, default: nil
  attr :contact_id, :integer, default: nil
  attr :name, :string
  attr :class, :string
  def render(assigns) do
    ~H"""
      <select 
        id={@id}
        name={@name}
        class={@class}
        phx-target={@myself}
        phx-value-id={@autosubmit_id}
        phx-change={JS.push("select_person_change") |> JS.dispatch("submit", to: "##{@autosubmit_to}")}
       >
        <%= for contact <- @available_persons do %>
          <option 
            selected={if @contact_id != nil do contact.id == @contact_id else false end}
            value={contact.id} 
            id={"#{@id}-#{contact.id}"}
          >
            <%= Tools.display_person_name(contact) %>                      
          </option>
        <% end %>
        <option 
          id={"#{@id}-createnew"}
          value="-create-new"
        >
          Create new...
        </option>
      </select>

    """
  end


  @impl true
  def handle_event("select_person_change",
    params,
    %Phoenix.LiveView.Socket{} = socket
  ) do
    IO.inspect(params)
    IO.inspect(socket.assigns)

    {:noreply, socket}
  end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{}
    {:ok, socket |> assign(default_assigns)}
  end
end