//= require curation_concerns/manage_repeating_fields
//= require curation_concerns/help_modal
//= require curation_concerns/select_works
//= require curation_concerns/link_users
//= require curation_concerns/link_groups
//= require curation_concerns/proxy_rights
//= require curation_concerns/facet_mine
//= require curation_concerns/accept_contributor_agreement
//= require curation_concerns/proxy_submission
//= require curation_concerns/embargoes


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
