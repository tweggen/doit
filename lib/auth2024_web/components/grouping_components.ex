defmodule Auth2024Web.GroupingComponent do
  use Phoenix.Component

	def group_by_func(sort_by_column) do
		case sort_by_column do
			"date" -> fn (item) -> item.due end
			"contact" -> fn (item) -> "#{item.contact.given_name} #{item.contact.family_name}" end
		end
	end

	def group_by_label(item, sort_by_column) do
		case sort_by_column do
			"date" -> item.due
			"contact" -> item.contact.given_name
		end
	end

	slot :inner_block, required: true
	slot :header


  def for_items(assigns) do
		# In this, group the files by date, sorted by id.		
		item_map = assigns.items
    |> Enum.group_by(group_by_func(assigns.sort_by_column))
    |> Enum.map(fn {attr, items} -> 
      {attr, Enum.sort_by(items, & &1.id)}
    end)
    |> Enum.into(%{})	
    ~H"""
    	<%= for {attr, item_list} <- item_map do %>
    		<div>
      		<%= render_slot(@header, attr) || "sort_by_column" %>
    		</div>
    		<%= for item <- item_list do %>
					<%= render_slot(@inner_block, item) %>
    		<% end %>
    	<% end %>
    """
  end

end