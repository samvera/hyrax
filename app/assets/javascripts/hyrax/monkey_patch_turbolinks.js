/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Monkey patch Turbolinks to render 401
// See https://github.com/turbolinks/turbolinks/issues/179
//     https://github.com/samvera/hyrax/issues/617
if (typeof Turbolinks !== 'undefined' && Turbolinks !== null) {
  Turbolinks.HttpRequest.prototype.requestLoaded = function() {
    return this.endRequest(() => {
      if ((200 <= this.xhr.status && this.xhr.status < 300) || (this.xhr.status === 401)) {
        return this.delegate.requestCompletedWithResponse(this.xhr.responseText, this.xhr.getResponseHeader("Turbolinks-Location"));
      } else {
        this.failed = true;
        return this.delegate.requestFailedWithStatusCode(this.xhr.status, this.xhr.responseText);
      }
    });
  };

  // Fixes a back/forward navigation problem with UV and turbolinks
  // See https://github.com/samvera/hyrax/issues/2964
  // This is based on https://github.com/turbolinks/turbolinks/issues/219#issuecomment-275838923
  $(window).on('popstate', event => {
    this.turbolinks_location = Turbolinks.Location.wrap(window.location);
    if (Turbolinks.controller.location.requestURL === this.turbolinks_location.requestURL) { return; }
    if (event.state != null ? event.state.turbolinks : undefined) { return; }
    if ((this.window_turbolinks = window.history.state != null ? window.history.state.turbolinks : undefined)) {
      return Turbolinks.controller.historyPoppedToLocationWithRestorationIdentifier(this.turbolinks_location, this.window_turbolinks.restorationIdentifier);
    } else {
      return Turbolinks.controller.historyPoppedToLocationWithRestorationIdentifier(this.turbolinks_location, Turbolinks.uuid());
    }
  });
}
