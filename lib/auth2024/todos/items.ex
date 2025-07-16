defmodule Auth2024.Todos.Items do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Auth2024.Repo
  alias Auth2024.Todo.{Item, Person}
  alias Auth2024.Todos.{QueryFilters}


  def get_item!(id), do: Repo.get!(Item, id)
  
  
  def list_items_normalized(user, filter_by_value, sort_by_column) do
    # We have different base queries depending on if we order by date
    # or by user, eventually grouping by each.
    case sort_by_column do
      "date" ->
        Item
        |> order_by(desc: :inserted_at)
      "contact" ->
        Item
        |> order_by(asc: :contact_id, desc: :inserted_at)
    end
    |> where([a], a.user_id == ^user.id)
    |> QueryFilters.apply_filter(filter_by_value)
    |> Repo.all()
  end
  

  def list_items(user, filter_by_value, solo_contact, sort_by_column) do
    # We have different base queries depending on if we order by date
    # or by user, eventually grouping by each.
    case sort_by_column do
      "date" ->
        Item
        |> order_by(desc: :inserted_at)
      "contact" ->
        Item
        |> order_by(asc: :contact_id, desc: :inserted_at)
    end
    |> where([a], a.user_id == ^user.id)
    |> QueryFilters.apply_filter(filter_by_value)
    |> Repo.all()
    |> Repo.preload([:contact, :author, :user])
  end


  def hydrate_item(item) do
    item
    |> Repo.preload([:contact, :author])
  end


  def add_item(user, attrs) do
    IO.inspect("add_item")
    IO.inspect(attrs)
    IO.inspect(user)
    user
    |> Ecto.build_assoc(:todos, attrs)
    |> Repo.insert()
  end


  @doc false
  def update_item(_user, %Item{} = item, attrs) do
    if !Map.has_key?(item, :id) && !Map.has_key?(attrs, :id) && !Map.has_key?(attrs, "id") do
      raise ArgumentError, message: "Expected id as atom or string to be part of item."
    end
    item
    |> Item.update_changeset(attrs)
    |> Repo.update()
  end


  @doc false
  def update_item_contact(_user, %Item{} = item, attrs) do
    item
    # We need the contact pre-loaded in the item we are modifying.
    |> Repo.preload([:contact])
    |> Item.changeset_contact(attrs)
    |> Repo.update()
  end


  @doc false
  def delete_item(_user, id) do
    get_item!(id)
    |> Item.update_changeset(%{status: 2})
    |> Repo.update()
  end

  @doc false
  def clear_completed() do
    completed_items = from(i in Item, where: i.status == 1)
    Repo.update_all(completed_items, set: [status: 2])
  end


end
