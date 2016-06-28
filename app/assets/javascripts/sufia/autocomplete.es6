export class Autocomplete {
  constructor() {
  }

  // This is the initial setup for the form.
  setup() {
      $('[data-autocomplete]').each((index, value) => {
          let selector = $(value)
          switch (selector.data('autocomplete')) {
            case "subject":
              this.autocompleteSubject(selector);
              break;
            case "language":
              this.autocompleteLanguage(selector);
              break;
            case "based_near":
              this.autocompleteLocation(selector);
              break;
          }
      });
  }

  // attach an auto complete based on the field
  fieldAdded(cloneElem) {
    var $cloneElem = $(cloneElem);
    // FIXME this code (comparing the id) depends on a bug. Each input has an id and
    // the id is duplicated when you press the plus button. This is not valid html.
    if (/_based_near$/.test($cloneElem.attr("id"))) {
        this.autocompleteLocation($cloneElem);
    } else if (/_language$/.test($cloneElem.attr("id"))) {
        this.autocompleteLanguage($cloneElem);
    } else if (/_subject$/.test($cloneElem.attr("id"))) {
        this.autocompleteSubject($cloneElem);
    }
  }

  autocompleteLocation(field) {
      var loc = require('sufia/autocomplete/location');
      new loc.Location(field, field.data('autocomplete-url'))
  }

  autocompleteSubject(field) {
      var subj = require('sufia/autocomplete/subject');
      new subj.Subject(field, field.data('autocomplete-url'))
  }

  autocompleteLanguage(field) {
      var lang = require('sufia/autocomplete/language');
      new lang.Language(field, field.data('autocomplete-url'))
  }
}
