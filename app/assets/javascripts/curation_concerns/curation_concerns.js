//= require hydra-editor/hydra-editor
//= require curation_concerns/facet_mine
//= require curation_concerns/embargoes


// Initialize plugins and Bootstrap dropdowns on jQuery's ready event as well as
// Turbolinks's page change event.
Blacklight.onLoad(function() {
  $('abbr').tooltip();

  $("[data-toggle='dropdown']").dropdown();

});
