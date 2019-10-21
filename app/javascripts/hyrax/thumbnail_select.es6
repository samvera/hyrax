// Dynamically load the file options into the "Thumbnail" select field.
export default class {
  /*
   * @param {String} url the search endpoint
   * @param {jQuery} the field to add the select to
   */
  constructor(url, field) {
    this.loadThumbnailOptions(url, field)
  }

  // Dynamically load the file options into the "Thumbnail" select field.
  loadThumbnailOptions(url, field) {
      field.select2({
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
