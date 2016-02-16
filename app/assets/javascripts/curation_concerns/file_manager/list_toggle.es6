Blacklight.onLoad(function() {
  $("*[data-action=list-toggle] button").click(function() {
    $(this).parent().find("button").toggleClass("active")
    $("#sortable").toggleClass("grid")
  })
})
