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

  def rename_prompt
    javascript_tag %Q{
  function x_rename_prompt()
  {
    var name = prompt('Enter New Name', '');
    if (name == null) return;
    $('#thing_name_wrapper').textContent=name;
    #{remote_function :url => {:action => 'rename_thing', :id =>
@thing.id}, :with => "'name=' + escape(name)", :method=>'post' }
  }
    
}
  end

end