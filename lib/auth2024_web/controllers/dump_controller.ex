defmodule Auth2024Web.DumpController do
  use Auth2024Web, :controller
  alias Auth2024.Todos


  def index(conn, params) do
    # IO.inspect(conn)
    # IO.inspect(params)
    user = conn.assigns.current_user

    items = Todos.list_items_normalized(user, "all", "date")
    persons = Todos.list_persons!(user)

    conn
    |> put_status(200)
    |> json(
      %{
        :format => 1,
        :exportedAt => DateTime.utc_now(),
        :items => 
          Enum.map(items,
            fn item -> %{
              :id => item.id,
              :status => item.status,
              :due => item.due,
              :caption => item.caption,
              :content => item.content,
              :authorId => item.author_id,
              :contactId => item.contact_id,
              :insertedAt => item.inserted_at,
              :updatedAt => item.updated_at
            } end
          ),
        :persons => 
          Enum.map(persons,
            fn person -> %{
              :id => person.id,
              :status => person.status,
              :email => person.email,
              :familyName => person.family_name,
              :givenName => person.given_name,
              :owningUserId => person.owning_user_id,
              :userId => person.user_id,
              :insertedAt => person.inserted_at,
              :updatedAt => person.updated_at
            } end
          )
      }
    )
  end
end
