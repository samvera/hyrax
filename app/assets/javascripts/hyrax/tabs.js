
Blacklight.onLoad(function () {
  // When we visit a link to a tab, open that tab.
  var url = document.location.toString();
  if (url.match('#')) {
    $('.nav-tabs a[href="#' + url.split('#')[1] + '"]').tab('show');
  }
});

if (typeof Turbolinks === "undefined") {
  // navigate to the selected tab or the first tab
  function tabNavigation(e) {
      var activeTab = $('[href="' + location.hash + '"]');
      if (activeTab.length) {
          activeTab.tab('show');
      } else {
          var firstTab = $('.nav-tabs a:first');
          // select the first tab if it has an id and is expected to be selected
          if ((firstTab[0] !== undefined) && (firstTab[0].id != "")){
            $(firstTab).tab('show');
          }
      }
  }

  // Messing with the push state means that turbolinks will be unable to handle
  // the back button because the event will not have been a turbolinks event.
  // See https://github.com/turbolinks/turbolinks/blob/c73e134731ad12b2ee987080f4c905aaacdebba1/src/turbolinks/history.coffee#L28
  Blacklight.onLoad(function () {
    // Change the url when a tab is clicked.
    $('a[data-toggle="tab"]').on('click', function(e) {
      history.pushState(null, null, $(this).attr('href'));
    });
    // navigate to a tab when the history changes (back button)
    window.addEventListener("popstate", tabNavigation);
  })
}
