$(document).ready ->

  $("#submit").click ->
    account = $("#account").val()
    window.location = "/#{account}" if account
    false
