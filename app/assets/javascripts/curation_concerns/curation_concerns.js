//= require hydra-editor/hydra-editor
//= require curation_concerns/help_modal
//= require curation_concerns/select_works
//= require curation_concerns/link_users
//= require curation_concerns/link_groups
//= require curation_concerns/proxy_rights
//= require curation_concerns/facet_mine
//= require curation_concerns/proxy_submission
//= require curation_concerns/embargoes


// Initialize plugins and Bootstrap dropdowns on jQuery's ready event as well as
// Turbolinks's page change event.
Blacklight.onLoad(function() {
  $('abbr').tooltip();
  $('.link-users').linkUsers();
  $('.link-groups').linkGroups();
  $('.proxy-rights').proxyRights();


//  $('#set-access-controls .datepicker').datepicker({
//    format: 'yyyy-mm-dd',
//    startDate: '+1d'
//  });

  $("[data-toggle='dropdown']").dropdown();

});
