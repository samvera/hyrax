# Monkey patch Turbolinks to render 401
# See https://github.com/turbolinks/turbolinks/issues/179
#     https://github.com/samvera/hyrax/issues/617
if Turbolinks?
  Turbolinks.HttpRequest.prototype.requestLoaded = ->
    @endRequest =>
      if 200 <= @xhr.status < 300 or @xhr.status == 401
        @delegate.requestCompletedWithResponse(@xhr.responseText, @xhr.getResponseHeader("Turbolinks-Location"))
      else
        @failed = true
        @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)

  # Fixes a back/forward navigation problem with UV and turbolinks
  # See https://github.com/samvera/hyrax/issues/2964
  # This is based on https://github.com/turbolinks/turbolinks/issues/219#issuecomment-275838923
  $(window).on 'popstate', (event) =>
    @turbolinks_location = Turbolinks.Location.wrap(window.location)
    return if Turbolinks.controller.location.requestURL == @turbolinks_location.requestURL
    return if event.state?.turbolinks
    if @window_turbolinks = window.history.state?.turbolinks
      Turbolinks.controller.historyPoppedToLocationWithRestorationIdentifier(@turbolinks_location, @window_turbolinks.restorationIdentifier)
    else
      Turbolinks.controller.historyPoppedToLocationWithRestorationIdentifier(@turbolinks_location, Turbolinks.uuid())
