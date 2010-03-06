$(document).ready(function(){
  init();
  //event handlers
  $("#aboutButton").click(function(){
    showPage($("#about")[0]);
  })
  $("#twitter_link").click(function(){
    window.location.href="http://twitter.com/inscryb"
  })
  $("#ask_button").click(function(){
    var question = $("#question_box").val()
    var guid = $("#guid_place").text()
    $.ajax({
      dataType:'script',
      type:'post',
      data: 'question=' + encodeURIComponent(question),
      url:'/places/' + guid +'/ask',
      success: function(data){
        var parse_data=eval('('+data+')')
        if (parse_data=="OK") {
          alert ("Request sent");
        } else {
          alert(data)
      }
      },
      complete: function(){
      }
    });
    return false;

  });
})

