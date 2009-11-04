# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def set_focus_to_id(id)
    javascript_tag("$('#{id}').focus()");
  end

  def clear_field_and_focus(id)
    return "$('#{id}').value='';$('#{id}').focus();";
  end

end