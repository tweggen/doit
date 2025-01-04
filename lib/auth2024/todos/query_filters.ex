defmodule Auth2024.Todos.QueryFilters do

  @moduledoc """
  Shared query filtering logic.
  """

  import Ecto.Query

  def apply_filter(query, filter_by_value) do
    case filter_by_value do
      "completed" -> where(query, [a], is_nil(a.status) or a.status==1)
      "all" -> where(query, [a], is_nil(a.status) or a.status != 2)
      "active" -> where(query, [a], is_nil(a.status) or a.status==0)
    end
  end
end
  