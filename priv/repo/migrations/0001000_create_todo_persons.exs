defmodule Auth2024.Repo.Migrations.CreateTodoPersons do
  use Ecto.Migration

  def change do
    create table(:todo_persons) do
      add :status, :integer
      add :family_name, :string
      add :given_name, :string
      
      add :user_id, references(:users)

      timestamps(type: :utc_datetime)
    end

    create index(:todo_persons, [:family_name])
    create index(:todo_persons, [:user_id])

  end
end
