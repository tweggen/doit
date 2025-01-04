defmodule Auth2024.Todos.Persons do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Auth2024.Repo
  alias Auth2024.Todo.{Person}

  
  def get_person!(id), do: Repo.get!(Person, id)


  def list_persons!(_user) do
    Person
    |> order_by(asc: :family_name)
    |> Repo.all()
  end


  def hydrate_person(person) do
    person
    |> Repo.preload([:user])
  end


  @doc false
  def add_person(user, attrs) do
    Person.create_changeset(attrs, user.id)
    |> Repo.insert()
  end


  @doc false
  def add_person_to_user(user, attrs) do
    user
    |> Ecto.build_assoc(:person, attrs)
    |> Repo.insert()
  end


  @doc false
  def update_person_due(user, contact_id, duedate) do
    person_items = from(i in Item, where: i.user_id == ^user.id and i.contact_id == ^contact_id)
    Repo.update_all(person_items, set: [due: duedate])
  end


  @doc false
  def find_person_for_user(user) do
    case Repo.get_by(Person, [user_id: user.id, owning_user_id: user.id]) do
      nil ->
        # Entity doesn't exist, create it
        #changeset = %{
        #  # Set initial attributes here
        #  # ...
        #}
        #{:ok, entity} = Repo.insert(changeset)
        #entity
        add_person_to_user(user, %{owning_user_id: user.id, family_name: user.email, email: user.email, status: 0})

      entity ->
        # Entity already exists, return it
        entity
    end
  end


  def search_person_by_name(user, family_name, given_name) do
    Person
    |> where([p],
         p.owning_user_id == ^user.id
         and
         p.family_name == ^family_name
         and (
           (^given_name == "" and is_nil(p.given_name))
           or ^given_name == p.given_name
           )
       )
    |> order_by(asc: :family_name)
    |> Repo.all()
  end


  def search_person_by_email(user, email) do
    Person
    |> where([p],
         p.owning_user_id == ^user.id
         and
         p.email == ^email
       )
    |> order_by(asc: :email)
    |> Repo.all()
  end


  #def search_person_family_names(user, name) do
  #  Person
  #  |> where([p], 
  #      p.owning_user_id == ^user.id
  #      and
  #      p.family_name == ^name
  #    )
  #  |> order_by(asc: :family_name)
  #  |> Repo.all()
  #end


  #def search_person_family_name(user, name) do
  #  List.first(search_person_family_names(user, name))
  #end


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


  @doc false
  def update_person(_user, %Person{} = person, attrs) do
    if !Map.has_key?(person, :id) && !Map.has_key?(attrs, :id) && !Map.has_key?(attrs, "id") do
      raise ArgumentError, message: "Expected id as atom or string to be part of person."
    end
    person
    |> Person.update_changeset(attrs)
    |> Repo.update()
  end


  def possibly_add_person(user, email, family_name, given_name) do
    similarily_named_person = search_person_by_name(
      user, family_name, given_name)
    person_with_email = search_person_by_email(
      user, email)

    if [] != similarily_named_person ||  [] != person_with_email do
      { -1, "Person with similar name or email already exists." }
    else
      all_person_params = %{
        "status" => 0,
        "email" => email,
        "family_name" => family_name,
        "given_name" => given_name,
        "owning_user_id" => user.id,
        "user_id" => user.id
      }
      case add_person(user, all_person_params) do
        {:error, message} ->
          { -1, message }

        {:ok, person} ->
          { person.id, person }
      end
    end
  end

end
