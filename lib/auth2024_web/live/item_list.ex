defmodule Auth2024Web.ItemList do
  @moduledoc false
  #use Phoenix.Socket
  use Phoenix.LiveView
  alias Phoenix.LiveView.JS
  alias Auth2024.Todos
  
  # This is specific for caption
  def default_editing_item_values(
    %Phoenix.LiveView.Socket{} = socket, text
  ) do
    {erl_date, _erl_time} = :calendar.local_time()
    {:ok, date} = Date.from_erl(erl_date)
    %{
      caption: text,
      status: 0,
      author: socket.assigns.current_person,
      contact: socket.assigns.current_person,
      due: date
    }
  end


  def query_items(
    %Phoenix.LiveView.Socket{} = socket
  ) do
    if connected?(socket) do
      items = Todos.list_items(
        socket.assigns.current_user, 
        Todos.config_filter_by_value(socket.assigns.user_config),
        Todos.config_sort_by_column(socket.assigns.user_config)
      )

      {erl_date, _erl_time} = :calendar.local_time()
      {:ok, date} = Date.from_erl(erl_date)
      %{count: count, n_late: n_late} = Enum.reduce(
        items, 
        %{count: 0, n_late: 0},
        fn item, acc -> %{
          count: (if (item.status==0), do: acc.count + 1, else: acc.count),
          n_late: (if item.status==0 && item.due != nil && date != nil && Date.compare(item.due, date) == :lt && item.due.day != date.day, do: acc.n_late+1, else: acc.n_late) 
        }
        end
      )
      socket 
      |> assign(
        items: items,
        n_items: count,
        n_late: n_late,
        percent_late: (if count>0, do: n_late/count * 100, else: 0.0)
      )
    else
      socket 
      |> assign(
        items: [],
        n_items: 0,
        n_late: 0,
        percent_late: 0.0
      )
    end
  end


end
