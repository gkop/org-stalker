window.showElements = ->
  $(".element").css("background", "none")
  $(".element").css("color", "#00ff1a")
  $(q).find("a").css("color", "#00ff1a")
  if window.action_shown
    action = window.action_shown
  else
    action = "element"
  if window.user_shown
    user = "[data-user='" + window.user_shown + "']"
  else
    user = ""
  q = "." + action + user
  $(q).css("background", "#00ff1a")
  $(q).css("color", "black")
  $(q).find("a").css("color", "black")


$(document).ready ->

  $(".all_events").masonry itemSelector: ".element"

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


