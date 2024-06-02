defmodule Auth2024.Repo.Migrations.CreateTodoPersons do
  use Ecto.Migration

  def change do
    create table(:todo_persons) do
      add :status, :integer
      add :family_name, :string
      add :given_name, :string

      timestamps(type: :utc_datetime)
    end

    create index(:todo_persons, [:family_name])
  end
end
