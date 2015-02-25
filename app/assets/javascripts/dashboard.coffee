# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

Turbolinks.enableProgressBar(true)

ready = ->
    $('[data-toggle="tooltip"]').tooltip()

$(document).on('page:load', ready).ready(ready);