defmodule Auth2024Web.DisplayItemComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias Auth2024Web.Tools

  attr :on_click, :string, default: nil
  attr :item_id, :string
  attr :class, :string
  slot :inner_block, required: true
  def list_caption(assigns) do
    ~H"""
      <label 
        class="flex-none min-w-0 min-h-0 font-semibold text-slate-900 text-m p-0 margin-none text-nowrap text-ellipsis overflow-hidden" 
        phx-click={@on_click}
        phx-value-item_id={@item_id}
      >
        <%= render_slot(@inner_block) %>
      </label>
    """
  end
end

