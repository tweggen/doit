defmodule Auth2024.Todos.QueryFilters do

  @moduledoc """
  Shared query filtering logic.
  """

  import Ecto.Query


  def apply_solo(query, nil) do
    query
  end

  @doc """
  Apply the filter rule: 
  - "completed", "all" or "active" values shall be displayed.
  """
  def apply_solo(query, filter_by_value) do
    where(query, [a], a.contact_id == ^filter_by_value)
  end

  @doc """
  Apply the filter rule: 
  - "completed", "all" or "active" values shall be displayed.
  """
  def apply_filter(query, filter_by_value) do
    case filter_by_value do
      "completed" -> where(query, [a], is_nil(a.status) or a.status==1)
      "all" -> where(query, [a], is_nil(a.status) or a.status != 2)
      "active" -> where(query, [a], is_nil(a.status) or a.status==0)
    end
  end
end
