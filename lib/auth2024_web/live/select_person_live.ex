defmodule Auth2024Web.SelectPersonComponent do
  use Auth2024Web, :live_component

  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  #use Phoenix.LiveComponent


  attr :autosubmit, :boolean, default: false
  attr :item_id, :string
  attr :contact_id, :integer, default: nil
  attr :name, :string
  attr :class, :string
  def render(assigns) do
    ~H"""
    <select 
      id={@id}
      name={@name}
      class={@class}
      phx-target={if @autosubmit==true do @myself else @myself end}
      phx-value-id={if @autosubmit==true do @item_id else nil end}
      phx-change="select_person_change"
     >
      <%= for contact <- @available_persons do %>
        <option 
          selected={if @contact_id != nil do contact.id == @contact_id else false end}
          value={contact.family_name} 
          id={"select-todo-item-contact-#{@item_id}-#{contact.id}"}
        >
          <%= contact.family_name %>                      
        </option>
      <% end %>
      <option 
        id={"select-todo-iten-new-contact-#{@item_id}"}
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
    if @autosubmit==true do
      JS.dispatch("submit", to: "#form-todo-item-contact-#{@item_id}")
    else 
      nil
    end
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