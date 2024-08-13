defmodule Auth2024Web.GroupingComponent do
  use Phoenix.Component
  alias Auth2024Web.Tools

	def group_by_func(sort_by_column) do
		case sort_by_column do
			"date" -> fn (item) -> item.due end
			"contact" -> fn (item) -> item.contact end
		end
	end


	def sort_items_func(sort_by_column) do
		case sort_by_column do
			"date" -> fn (item) -> Tools.display_person_name(item.contact) end
			"contact" -> fn (item) -> item.due end
			#_x -> fn (item) -> item.id end
		end
	end


	def group_by_header_data(sort_by_column) do
		case sort_by_column do
			"date" -> fn (item) -> item.due end
			"contact" -> fn (item) -> item.contact.id end
		end
	end


	slot :inner_block, required: true
	slot :header


  def for_items(assigns) do
		# In this, group the files by date, sorted by id.		
		item_map = assigns.items
    |> Enum.group_by(group_by_func(assigns.sort_by_column))
    |> Enum.map(fn {attr, items} -> 
      {attr, Enum.sort_by(items, sort_items_func(assigns.sort_by_column))}
    end)
    |> Enum.into(%{})	
    ~H"""
    	<%= for {attr, item_list} <- item_map do %>
    		<div class="flex-none flex flex-col min-h-0">
      		<%= render_slot(@header, attr) || "sort_by_column" %>
    		</div>
    		<%= for item <- item_list do %>
					<%= render_slot(@inner_block, item) %>
    		<% end %>
    	<% end %>
    """
  end

end