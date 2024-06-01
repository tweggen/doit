defmodule Auth2024.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Auth2024.Repo

  alias Auth2024.Todo.{Item}

  ## Database getters

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %User{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Item
    |> order_by(desc: :inserted_at)
    |> where([a], is_nil(a.status) or a.status != 2)
    |> Repo.all()
  end

  ## Item creation

  @doc """
  Adds an item

  ## Examples

      iex> add_item(%{field: value})
      {:ok, %User{}}

      iex> add_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item caption.

  ## Examples

      iex> change_item_caption(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item_caption(%Item{} = item, attrs \\ %{}) do
    Item.caption_changeset(item, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item content.

  ## Examples

      iex> change_item_content(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item_content(%Item{} = item, attrs \\ %{}) do
    Item.content_changeset(item, attrs)
  end

  # "soft" delete
  def delete_item(id) do
    get_item!(id)
    |> Item.changeset(%{status: 2})
    |> Repo.update()
  end

  @doc """
  Set status to 2 for item with status 1,
  ie delete completed item
  """
  def clear_completed() do
    completed_items = from(i in Item, where: i.status == 1)
    Repo.update_all(completed_items, set: [status: 2])
  end

end
