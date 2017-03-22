# Monkey patch Turbolinks to render 401
# See https://github.com/turbolinks/turbolinks/issues/179
#     https://github.com/projecthydra-labs/hyrax/issues/617
if Turbolinks?
  Turbolinks.HttpRequest.prototype.requestLoaded = ->
    @endRequest =>
      if 200 <= @xhr.status < 300 or @xhr.status == 401
        @delegate.requestCompletedWithResponse(@xhr.responseText, @xhr.getResponseHeader("Turbolinks-Location"))
      else
        @failed = true
        @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)
