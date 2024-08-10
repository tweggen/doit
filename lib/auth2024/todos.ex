defmodule Auth2024.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias Auth2024.Repo

  alias Auth2024.Todo.{Item, Person}

  ## Database getters

  @doc false
  def get_item!(id), do: Repo.get!(Item, id)

  def get_person!(id), do: Repo.get!(Person, id)

  defp apply_filter(query, filter_by_value) do
    case filter_by_value do
      "completed" -> where(query, [a], is_nil(a.status) or a.status==1)
      "all" -> where(query, [a], is_nil(a.status) or a.status != 2)
      "active" -> where(query, [a], is_nil(a.status) or a.status==0)
    end
  end


  @doc false
  def list_items(user, filter_by_value, sort_by_column) do
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
    |> apply_filter(filter_by_value)
    |> Repo.all()
    |> Repo.preload([:contact, :author, :user])
  end


  def list_persons!(user) do
    Person
    |> order_by(asc: :family_name)
    |> Repo.all()
  end



  def hydrate_item(item) do
    item
    |> Repo.preload([:contact, :author])
  end


  def hydrate_person(person) do
    person
    |> Repo.preload([:user])
  end


  @doc false
  def add_item(user, attrs) do
    user
    |> Ecto.build_assoc(:todos, attrs)
    |> Repo.insert()
  end


  @doc false
  def add_person(_user, attrs) do
    Person.create_changeset(attrs)
    |> Repo.insert()
  end


  @doc false
  def add_person_to_user(user, attrs) do
    user
    |> Ecto.build_assoc(:person, attrs)
    |> Repo.insert()
  end


  @doc false
  def find_person_for_user(user) do
    case Repo.get_by(Person, [user_id: user.id]) do
      nil ->
        # Entity doesn't exist, create it
        #changeset = %{
        #  # Set initial attributes here
        #  # ...
        #}
        #{:ok, entity} = Repo.insert(changeset)
        #entity
        add_person_to_user(user, %{family_name: user.email, status: 0})

      entity ->
        # Entity already exists, return it
        entity
    end
  end


  def search_person_by_name(family_name, given_name) do
    Person
    |> where([p], 
        p.family_name == ^family_name 
        and (
          (^given_name == "" and is_nil(p.given_name)) 
          or ^given_name == p.given_name
        )
      )
    |> order_by(asc: :family_name)
    |> Repo.all()
  end


  def search_person_family_names(name) do
    Person
    |> where([p], p.family_name == ^name)
    |> order_by(asc: :family_name)
    |> Repo.all()
  end


  def search_person_family_name(name) do
    List.first(search_person_family_names(name))
  end


  def search_persons_beginning(stem) do
    Person
    |> where([p], like(p.family_name, ^"%#{String.replace(stem, "%", "\\%")}%"))
    |> order_by(asc: :family_name)
    |> Repo.all()
  end

  def search_person_beginning(stem) do
    matches = search_persons_beginning(stem)
    List.first(matches)
  end

  ## Settings

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
  def update_person(_user, %Person{} = person, attrs) do
    if !Map.has_key?(person, :id) && !Map.has_key?(attrs, :id) && !Map.has_key?(attrs, "id") do
      raise ArgumentError, message: "Expected id as atom or string to be part of person."
    end
    person
    |> Person.update_changeset(attrs)
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
