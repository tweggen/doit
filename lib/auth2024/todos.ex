defmodule Auth2024.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Auth2024.Repo

  alias Auth2024.Todo.{Item, Person}
  alias Auth2024.Accounts.User

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
  def list_items(user) do
    Item
    |> order_by(desc: :inserted_at)
    |> where([a], a.user_id == ^user.id)
    |> where([a], is_nil(a.status) or a.status != 2)
    |> Repo.all()
    |> Repo.preload([:contact, :author, :user])
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
  def add_item(user, attrs) do
    user
    |> Ecto.build_assoc(:todos, attrs)
    |> Repo.insert()
    #%Item{}
    #|> Item.changeset(attrs)
    #|> Repo.insert()
  end

  @doc """
  Adds an person

  ## Examples

      iex> add_person(%{field: value})
      {:ok, %Person{}}

      iex> add_person(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_person(user, attrs) do
    user
    |> Ecto.build_assoc(:person, attrs)
    |> Repo.insert()
  end


  @doc """
  Return a person for the user, creating it if it doesn't exist.

  ## Examples

      iex> add_person(%{field: value})
      {:ok, %Person{}}

      iex> add_person(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def find_person(user) do
    case Repo.get_by(Person, [user_id: user.id]) do
      nil ->
        # Entity doesn't exist, create it
        #changeset = %{
        #  # Set initial attributes here
        #  # ...
        #}
        #{:ok, entity} = Repo.insert(changeset)
        #entity
        add_person(user, %{family_name: user.email, status: 0})

      entity ->
        # Entity already exists, return it
        entity
    end
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
  def update_item(_user, %Item{} = item, attrs) do
    item
    |> Item.changeset_status(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a item caption

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item_caption(_user, %Item{} = item, attrs) do
    item
    |> Item.changeset_caption(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a item due date

  ## Examples

      iex> update_item_due(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item_due(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item_due(_user, %Item{} = item, attrs) do
    item
    |> Item.changeset_due(attrs)
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
  def delete_item(_user, id) do
    get_item!(id)
    |> Item.changeset_status(%{status: 2})
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
