defmodule Auth2024Web.GroupingComponent do
  use Phoenix.Component

	slot :inner_block, required: true
	slot :header

  def for_items(assigns) do
		# In this, group the files by date, sorted by id.		
		item_map = assigns.items
    |> Enum.group_by(& Map.get(&1, assigns.kind))
    |> Enum.map(fn {attr, items} -> 
      {attr, Enum.sort_by(items, & &1.id)}
    end)
    |> Enum.into(%{})	
    IO.inspect(item_map)
    ~H"""
    	<%= for {attr, item_list} <- item_map do %>
    		<div>
      		<%= render_slot(@header, attr) || "attr header" %>
    		</div>
    		<%= for item <- item_list do %>
					<%= render_slot(@inner_block, item) %>
    		<% end %>
    	<% end %>
    """
  end
end