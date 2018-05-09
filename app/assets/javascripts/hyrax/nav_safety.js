// To enable nav safety on a form:
// - Render the shared/nav-safety partial on the page.
// - Add the nav-safety-confirm class to the tab anchor element.
// - Add the nav-safety class to the form element.

Blacklight.onLoad(function() {
  $('.nav-safety-confirm').on('click', function(evt) {
    var dirtyData = $('#nav-safety-modal[dirtyData=true]');
    if (dirtyData.length > 0) {
      evt.preventDefault();
      evt.stopPropagation();
      $('#nav-safety-modal').modal('show');
    }
  });
  
  $('#nav-safety-dismiss').on('click', function(evt) {
    // evt.preventDefault();
    nav_safety_off();
    // $('#nav-safety-change-tab').modal('hide');
  });
  
  $('form.nav-safety').on('change', function(evt) {
    nav_safety_on();
  });
  $('form.nav-safety').on('reset', function(evt) {
    nav_safety_off();
  });
});

function nav_safety_on() {
  $('#nav-safety-modal')[0].setAttribute('dirtyData', true);
}

function nav_safety_off() {
  $('#nav-safety-modal')[0].setAttribute('dirtyData', false);
}

function tinymce_nav_safety(editor) {editor.on('Change', function (e) {
  $(e.target.targetElm).parents('form.nav-safety').change();
});
}
