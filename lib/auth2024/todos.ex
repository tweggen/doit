defmodule Auth2024.Todos do
  @moduledoc """
  Main facade for the todos content. Delegates to specific sub-modules.
  """

  import Ecto.Query, warn: false
  alias Auth2024.Repo
  alias Auth2024.Todo.{Item, Person, Config}
  alias Auth2024.Todos.{Configs, Items, Persons, QueryFilters}
  

  ## Delegates for item-related functions
  
  defdelegate get_item!(id), to: Items
  defdelegate list_items_normalized(user, filter_by_value, sort_by_column), to: Items
  defdelegate list_items(user, filter_by_value, solo_contact, sort_by_column), to: Items
  defdelegate hydrate_item(item), to: Items
  defdelegate add_item(user, attrs), to: Items
  defdelegate update_item(_user, item, attrs), to: Items
  defdelegate update_item_contact(_user, item, attrs), to: Items
  defdelegate delete_item(_user, id), to: Items
  defdelegate clear_completed(), to: Items
  
  
  ## Delegates for person-related functions

  defdelegate get_person!(id), to: Persons
  defdelegate list_persons!(_user), to: Persons
  defdelegate hydrate_person(person), to: Persons
  defdelegate add_person(user, attrs), to: Persons
  defdelegate add_person_to_user(user, attrs), to: Persons
  defdelegate update_person_due(user, contact_id, duedate), to: Persons
  defdelegate find_person_for_user(user), to: Persons
  defdelegate search_person_by_name(user, family_name, given_name), to: Persons
  defdelegate search_person_by_email(user, email), to: Persons
  defdelegate search_persons_beginning(stem), to: Persons
  defdelegate search_person_beginning(stem), to: Persons
  defdelegate update_person(_user, person, attrs), to: Persons
  defdelegate possibly_add_person(user, email, family_name, given_name), to: Persons
  
  
  ## Delegates for config-related functions

  defdelegate add_config_to_user(user, attrs), to: Configs
  defdelegate find_config_for_user(user), to: Configs
  defdelegate update_config(_user, config, attrs), to: Configs
  defdelegate config_filter_by_value(config), to: Configs
  defdelegate config_sort_by_column(config), to: Configs
  
  
  ## Filters
  
  defdelegate apply_filter(query, filter_by_value), to: QueryFilters

end
