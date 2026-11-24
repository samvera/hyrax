// app/assets/javascripts/hyrax/hydra_editor_override.js
$(document).on('ready page:load turbolinks:load', function() {
  $('.remove .sr-only').each(function() {
    $(this).html('this <span class="controls-field-name-text">field</span>');
  });
});
