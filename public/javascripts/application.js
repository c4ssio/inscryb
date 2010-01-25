$(document).ready(function(){
    init();
    //event handlers
    $("#aboutButton").click(function(){
        showPage($("#about")[0]);
    })
    $("#twitter_link").click(function(){window.location.href="http://twitter.com/inscryb"})
})

