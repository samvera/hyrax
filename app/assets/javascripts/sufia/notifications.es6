export class Notifications {
  // If URL is not provided, do nothing.
  // If there is a query parameter named "notification_seconds", it will
  // use it's value as the interval in seconds to poll.
  // Otherwise it will use the default interval passed as a parmeter
  constructor(url, default_interval) {
    if (!url)
      return;
    console.log(url);
    let interval = this.getIntervalSeconds(default_interval) * 1000
    this.poller(interval, url)
  }

  poller(interval, url) {
    setInterval(() => { console.log("again"); $.getScript(url) }, interval);
  }

  getIntervalSeconds(default_interval) {
    var seconds = parseInt(this.queryStringParam("notification_seconds"));
    return seconds || default_interval;
  }

  // During development allow the frequency of the notifications check to
  // be overwritten via query string parameter notification_seconds to
  // prevent cluttering the terminal with (mostly) meaninless messages.
  queryStringParam(key) {
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
}
