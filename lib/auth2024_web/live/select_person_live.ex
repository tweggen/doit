defmodule Auth2024Web.SelectPersonComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Auth2024Web.Tools

  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  #use Phoenix.LiveComponent

  attr :autosubmit_to, :string, default: nil
  attr :autosubmit_id, :string, default: nil
  attr :contact_id, :integer, default: nil
  attr :on_change, :string, default: nil
  attr :name, :string
  attr :class, :string
  def combobox(assigns) do
        # phx-target={@myself}
    ~H"""
      <select 
        id={@id}
        name={@name}
        class={@class}
        phx-value-id={@autosubmit_id}
        phx-change={
          js = 
            if @on_change != nil do
              JS.push(%JS{}, @on_change, value: %{key: "bla"})
            else
              %JS{}
            end
          js =
            if @autosubmit_to != nil do
              JS.dispatch(js, "submit", to: "##{@autosubmit_to}")
            else
              js
            end
          js
        }
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

      </select>

    """
  end


  #@impl true
  #def handle_event("select_person_change",
  #  params,
  #  %Phoenix.LiveView.Socket{} = socket
  #) do
  #  IO.inspect(params)
  #  IO.inspect(socket.assigns)
  #  {:noreply, socket}
  #end


  @impl true
  def mount(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    default_assigns = %{}
    {:ok, socket |> assign(default_assigns)}
  end
end