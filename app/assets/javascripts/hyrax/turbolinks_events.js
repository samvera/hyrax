// Fixes a problem with csrf tokens and turbolinks
// See https://github.com/rails/jquery-ujs/issues/456
$(document).on('turbolinks:load', function() {
  $.rails.refreshCSRFTokens();
});
