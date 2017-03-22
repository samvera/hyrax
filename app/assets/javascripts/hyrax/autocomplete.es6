import Default from './autocomplete/default'
import Work from './autocomplete/work'

export default class Autocomplete {
  // This is the initial setup for the form.
  setup (options) {
    var data = options.data
    var element = options.element
    switch (data.autocomplete) {
      case 'work':
        new Work(
          element,
          data.autocompleteUrl,
          data.user,
          data.id
        )
        break
      default:
        new Default(element, data.autocompleteUrl)
        break
    }
  }
}

