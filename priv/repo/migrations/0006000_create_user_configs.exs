defmodule Auth2024.Repo.Migrations.CreateUserConfigs do
  use Ecto.Migration

  def change do
    create table(:todo_configs) do
      add :user_id, references(:users), null: false

      add :properties, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:todo_configs, [:user_id])
  end
end
