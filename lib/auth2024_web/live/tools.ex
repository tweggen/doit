defmodule Auth2024Web.Tools do
  alias Auth2024.Todo.{Person}


  def easy_changeset_attrs(kind, value) do
    %{kind => value}
  end


  def display_due_date(item_due) do
    if is_nil(item_due) do
      # Get the current local date
      current_date = :calendar.local_time()

      # Format the date as "YYYY-MM-DD"
      formatted_date = Timex.format!(current_date, "{YYYY}-{0M}-{0D}")
      formatted_date
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