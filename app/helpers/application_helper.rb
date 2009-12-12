# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def set_focus_to_id(id)
    javascript_tag("$('##{id}').focus()");
  end

  def clear_field_and_focus(id)
    return "$('##{id}').val('');$('##{id}').focus()"
  end

  def submit_form_and_clear_field_and_focus(id)
    return "this.form.submit();$('##{id}').val('');$('##{id}').focus();";
  end

end
