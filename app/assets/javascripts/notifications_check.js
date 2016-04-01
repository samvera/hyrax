Blacklight.onLoad(function() {
  // During development allow the frequency of the notifications check to
  // be overwritten via query string parameter notification_seconds to
  // prevent cluttering the terminal with (mostly) meaninless messages.
  function queryStringParam(key) {
    var queryString, pairs, i;
    var value = null;
    try {
      queryString = document.location.search.substring(1);
      if (queryString === "") {
        return value; // nothing to do
      }
      pairs = queryString.split("&").map(function(el) {
        var pair = el.split("=");
        return {key: pair[0], value: pair[1]};
      });
      for(i = 0; i < pairs.length; i++) {
        if (pairs[i].key === key) {
          value = pairs[i].value;
          break;
        }
      }
    }
    catch(e) {
      // assume it's a malformed query string.
      value = null;
    }
    return value;
  }

  function getIntervalSeconds(default_interval) {
    var seconds = parseInt(queryStringParam("notification_seconds"));
    return seconds || default_interval;
  }

  function pollForUpdates(interval, url) {
    setInterval(function() {
      $.getScript(url);
    }, getIntervalSeconds(interval) * 1000);
  }

  $('[data-update-poll-url]').each(function() {
    var interval = $(this).data('update-poll-interval');
    var url = $(this).data('update-poll-url');

    pollForUpdates(interval, url);
  });
});
