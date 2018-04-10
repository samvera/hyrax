// Fixes a problem with csrf tokens and turbolinks
// See https://github.com/rails/jquery-ujs/issues/456
$(document).on('turbolinks:load', function() {
  $.rails.refreshCSRFTokens();
  // Explicitly set flag to false to force loading of UV
  // See https://github.com/samvera/hyrax/issues/2906
  window.embedScriptIncluded = false;
});
