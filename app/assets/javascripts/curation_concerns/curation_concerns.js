//= require hydra-editor/hydra-editor
//= require curation_concerns/facet_mine
//= require curation_concerns/embargoes
//= require curation_concerns/fileupload
//= require curation_concerns/file_manager/affix
//= require curation_concerns/file_manager/sorting
//= require curation_concerns/file_manager/save_manager
//= require curation_concerns/file_manager/member
//= require curation_concerns/single_use_links_manager
//= require curation_concerns/batch_select
//= require curation_concerns/collections


// Initialize plugins and Bootstrap dropdowns on jQuery's ready event as well as
// Turbolinks's page change event.
Blacklight.onLoad(function() {
  $('abbr').tooltip();

  $("[data-toggle='dropdown']").dropdown();
  $('a[data-toggle="popover"]').popover({ html: true })
                                 .click(function() { return false });

});
