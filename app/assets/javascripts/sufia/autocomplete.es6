import Location from 'sufia/autocomplete/location'
import Subject from 'sufia/autocomplete/subject'
import Language from 'sufia/autocomplete/language'
import Work from 'sufia/autocomplete/work'


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
              case "work":
                var user = selector.data('user');
                var id = selector.data('id');
                this.autocompleteWork(selector, user, id);
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
        new Location(field, field.data('autocomplete-url'))
    }

    autocompleteSubject(field) {
        new Subject(field, field.data('autocomplete-url'))
    }

    autocompleteLanguage(field) {
        new Language(field, field.data('autocomplete-url'))
    }

    autocompleteWork(field, user, id) {
        new Work(
            field,
            field.data('autocomplete-url'),
            user,
            id
        )
    }
}
