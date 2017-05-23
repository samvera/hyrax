export default class {
  constructor(elem) {
    this.loadThumbnailOptions(elem)

    let Participants = require('hyrax/admin/admin_set/participants');
    let participants = new Participants(elem.find('#participants'))
    participants.setup();

    let Visibility = require('hyrax/admin/admin_set/visibility');
    let visibilityTab = new Visibility(elem.find('#visibility'));
    visibilityTab.setup();
  }

  // Dynamically load the file options into the "Thumbnail" select field.
  loadThumbnailOptions(elem) {
      let url = window.location.pathname.replace('edit', 'files')
      elem.find('#admin_set_thumbnail_id').select2({
          ajax: { // Use the jQuery.ajax wrapper provided by Select2
              url: url,
              dataType: "json",
              results: function(data, page) {
                return { results: data }
              }
          },
          initSelection: function(element, callback) {
              // the input tag has a value attribute preloaded that points to a preselected repository's id
              // this function resolves that id attribute to an object that select2 can render
              // using its formatResult renderer - that way the repository name is shown preselected
              callback({ text: $(element).data('text') })
          }
      })
  }
}
