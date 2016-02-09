Blacklight.onLoad(function() {
  let tools = $("#file-manager-tools")
  if(tools.length > 0) {
    tools.affix({
      offset: {
        top: $("#file-manager-tools").parent().offset().top,
        bottom: function() {
          return $("#file-manager-extra-tools").outerHeight(true) + $("footer").outerHeight(true)
        }
      }
    })
  }
})
