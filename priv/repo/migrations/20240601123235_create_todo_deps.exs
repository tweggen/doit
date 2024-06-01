defmodule Auth2024.Repo.Migrations.CreateTodoDeps do
  use Ecto.Migration

  def change do
    create table(:todo_deps) do
      add :relation, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
