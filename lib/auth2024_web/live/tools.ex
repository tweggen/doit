defmodule Auth2024Web.Tools do
  alias Auth2024.Todo.{Person}
  alias Auth2024.Todos


  def assign_session_id(socket, %{"session_id" => session_id}) do
    Phoenix.Component.assign_new(socket, :session_id, fn -> session_id end)
  end


  def topic_id(%{:assigns => %{:session_id => session_id}}, topic), do: "#{topic}-#{session_id}"


  def send_notification(socket, topic, event) do
    full_topic = topic_id(socket, topic)
    Phoenix.PubSub.broadcast(Auth2024.PubSub, full_topic, event)
  end


  def easy_changeset_attrs(kind, value) do
    %{kind => value}
  end


  def display_due_date(item_due) do
    if is_nil(item_due) do
      # Get the current local date
      current_date = :calendar.local_time()

      # Format the date as "YYYY-MM-DD"
      Timex.format!(current_date, "{YYYY}-{0M}-{0D}")
    else
      Date.to_string(item_due)
    end
  end


  def display_string(str) do
  	if nil==str do
  	  "" 
  	else 
      str
    end
  end


  def display_person_name(%Person{} = person) do
  	if nil != person.family_name do
  	  if nil != person.given_name do
    		"#{person.family_name}, #{person.given_name}"
  	  else
    		"#{person.family_name}"
  	  end
  	else
  	  if nil != person.given_name do
    		"#{person.given_name}"
  	  else
    		"(unnamed person)"
  	  end
  	end
  end


  def open_edit_item(
    %Phoenix.LiveView.Socket{} = socket,
    item_id,
    focus_field
  ) do
    current_item = Todos.get_item!(item_id)

    socket 
    |> Auth2024Web.EditTodoLive.show(
      item_id,
      current_item,
      focus_field
    )
  end


  def push_js(
    %Phoenix.LiveView.Socket{} = socket, to, js
  ) do
    event_details = %{
      to: to,
      encodedJS: Phoenix.json_library().encode!(js.ops)
    }
    socket |> Phoenix.LiveView.push_event("exec-js", event_details);
  end

end
