// This code is to implement the tabs on the home page

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

Blacklight.onLoad(function () {
  // When we visit a link to a tab, open that tab.
  var url = document.location.toString();
  if (url.match('#')) {
    $('.nav-tabs a[href="#' + url.split('#')[1] + '"]').tab('show');
  }

  // Change the url when a tab is clicked.
  $('a[data-toggle="tab"]').on('click', function(e) {
    history.pushState(null, null, $(this).attr('href'));
  });
  // navigate to a tab when the history changes (back button)
  window.addEventListener("popstate", tabNavigation);
});
