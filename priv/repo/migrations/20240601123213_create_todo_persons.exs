defmodule Auth2024.Repo.Migrations.CreateTodoPersons do
  use Ecto.Migration

  def change do
    create table(:todo_persons) do
      add :family_name, :string
      add :given_name, :string
      add :status, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
