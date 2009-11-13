// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function submit_thing_link(id,context,mode,method) {
  //adds state parameters to hidden fields
  $("#thing_id").val(id);
  $("#thing_context").val(context);
  $("#thing_mode").val(mode);
  //submit form
  $("#thing_form").submit();
}