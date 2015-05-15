//= require worthwhile/manage_repeating_fields
//= require worthwhile/help_modal
//= require worthwhile/select_works
//= require worthwhile/link_users
//= require worthwhile/link_groups
//= require worthwhile/proxy_rights
//= require worthwhile/facet_mine
//= require worthwhile/proxy_submission
//= require worthwhile/embargoes


// Initialize plugins and Bootstrap dropdowns on jQuery's ready event as well as
// Turbolinks's page change event.
Blacklight.onLoad(function() {
  $('abbr').tooltip();

  $('body').on('keypress', '.multi-text-field', function(event) {
    var $activeField = $(event.target).parents('.field-wrapper'),
        $activeFieldControls = $activeField.children('.field-controls'),
        $addControl=$activeFieldControls.children('.add'),
        $removeControl=$activeFieldControls.children('.remove');
    if (event.keyCode == 13) {
      event.preventDefault();
      $addControl.click()
      $removeControl.click()
    }
  });
  $('.multi_value.form-group').manage_fields();
  $('.link-users').linkUsers();
  $('.link-groups').linkGroups();
  $('.proxy-rights').proxyRights();


//  $('#set-access-controls .datepicker').datepicker({
//    format: 'yyyy-mm-dd',
//    startDate: '+1d'
//  });

  $('.remove-member').on('ajax:success', function(){window.location.href = window.location.href});

  $("[data-toggle='dropdown']").dropdown();

});
