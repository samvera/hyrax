// Autocomplete for linked data elements using a select2 autocomplete widget
// After selecting something, the seleted item is immutable
export default class LinkedData {
  constructor(element, url) {
    this.url = url
    this.element = element
    this.activate()
  }

  activate() {
    this.element
      .select2(this.options(this.element))
      .on("change", (e) => { this.selected(e) })
  }

  // Called when a choice is made
  selected(e) {
    let result = this.element.select2("data")
    this.element.select2("destroy")
    this.element.val(result.label).attr("readonly", "readonly")
    // Adding d-block class to the remove button to show it after a selection is made.
    let removeButton = this.element.closest('.field-wrapper').find('.input-group-btn.field-controls .remove')
    removeButton.addClass('d-block')
    this.setIdentifier(result.id)
  }

  // Store the uri in the associated hidden id field
  setIdentifier(uri) {
    this.element.closest('.field-wrapper').find('[data-id]').val(uri);
  }

  options(element) {
    return {
      // placeholder: $(this).attr("value") || "Search for a location",
      minimumInputLength: 2,
      id: function(object) {
        return object.id;
      },
      text: function(object) {
        return object.label;
      },
      initSelection: function(element, callback) {
        // Called when Select2 is created to allow the user to initialize the
        // selection based on the value of the element select2 is attached to.
        // Essentially this is an id->object mapping function.
        var data = {
          id: element.val(),
          label: element[0].dataset.label || element.val()
        };
        callback(data);
      },
      ajax: { // Use the jQuery.ajax wrapper provided by Select2
        url: this.url,
        dataType: "json",
        data: function (term, page) {
          return {
            q: term // Search term
          };
        },
        results: function(data, page) {
          return { results: data };
        }
      }
    }
  }
}
