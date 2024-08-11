defmodule Auth2024.Repo.Migrations.ModifyTodoPersonsAddAssociatedUser do
  use Ecto.Migration

  def change do
    alter table(:todo_persons) do
      add :owning_user_id, references(:users)
      add :email, :string
    end
    create index(:todo_persons, [:owning_user_id])
    create index(:todo_persons, [:email])
  end

end

