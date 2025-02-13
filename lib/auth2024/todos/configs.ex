defmodule Auth2024.Todos.Configs do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Auth2024.Repo
  alias Auth2024.Todo.{Config}


  @doc false
  def add_config_to_user(user, attrs) do
    user
    |> Ecto.build_assoc(:config, attrs)
    |> Repo.insert()
  end


  @doc false
  def find_config_for_user(user) do
    case Repo.get_by(Config, [user_id: user.id]) do
      nil ->
        # Entity doesn't exist, create it
        case add_config_to_user(user, %{properties: %{}}) do
          {:ok, config} ->
            config
          _ ->
            %{properties: %{}}
        end
      entity ->
        # Entity already exists, return it
        entity
    end
  end


  def update_config(_user, %Config{} = config, attrs) do
    if !Map.has_key?(config, :id) && !Map.has_key?(attrs, :id) && !Map.has_key?(attrs, "id") do
      raise ArgumentError, message: "Expected id as atom or string to be part of person."
    end
    config
    |> Config.update_changeset(attrs)
    |> Repo.update()
  end


  def config_filter_by_value(config) do
    Map.get(config.properties, "filterByValue", "active")
  end

  def config_sort_by_column(config) do
    Map.get(config.properties, "sortByColumn", "date")
  end

end
