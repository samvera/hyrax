// To enable nav safety on a form:
// - Render the shared/nav-safety partial on the page.
// - Add the nav-safety-confirm class to the tab anchor element.
// - Add the nav-safety class to the form element.

Blacklight.onLoad(function() {
  $('.nav-safety-confirm').on('show.bs.tab', function(evt) {
    var previousTab = $(evt.relatedTarget).attr('href')
    var formId = $(previousTab).find('form').attr('id');
    if (typeof(formId)==="undefined") {
      formId = $(previousTab).closest('form').attr('id');
    }
    var dirtyData = $('#nav-safety-modal[dirtyData=true]');
    if (dirtyData.length > 0) {
      evt.preventDefault();
      evt.stopPropagation();
      $('#nav-safety-dismiss').data('form_id',formId);
      $('#nav-safety-dismiss').data('new_tab',$(evt.target).attr('href'));
      $('#nav-safety-modal').modal('show');
    }
  });

  $('#nav-safety-dismiss').on('click', function(evt) {
    nav_safety_off();
    // Reset form content before navigating away
    if ($(this).data('form_id')) {
      formId = '#'+$(this).data('form_id');
      $(formId)[0].reset();
    }
    // Navigate away from active tab to clicked tab
    window.location = $(this).data('new_tab');
  });

  $('#nav-safety-acknowledge').on('click', function(evt) {
    // Stay on current tab to allow save
    $('#nav-safety-modal').modal('hide');
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
