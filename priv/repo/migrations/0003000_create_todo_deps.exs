defmodule Auth2024.Repo.Migrations.CreateTodoDeps do
  use Ecto.Migration

  def change do
    create table(:todo_deps) do
      add :relation, :integer

      add :demanding_id, references(:todo_items), null: false
      add :required_id, references(:todo_items), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
