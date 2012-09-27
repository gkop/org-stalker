window.showElements = ->
  $(".element").hide(500)
  if window.action_shown
    action = window.action_shown
  else
    action = "element"
  if window.user_shown
    user = "[data-user='" + window.user_shown + "']"
  q = "." + action + user
  $(q).show(0);


$(document).ready ->

  $("#submit").click ->
    account = $("#account").val()
    window.location = "/#{account}" if account
    false


  $(".stat-block").click ->
    el = $(this).attr("data-action")
    window.action_shown = el
    window.showElements()

  $(".user_link").click (e) ->
    e.preventDefault()
    el = $(this).attr("data-login")
    window.user_shown = el
    window.showElements()


