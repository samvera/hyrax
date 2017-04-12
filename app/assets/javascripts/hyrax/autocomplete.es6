import Default from './autocomplete/default'
import Work from './autocomplete/work'
import LinkedData from './autocomplete/linked_data'

export default class Autocomplete {
  /**
   * Setup for the autocomplete field.
   * @param {jQuery} element - The input field to add autocompete to
   # @param {string} fieldName - The name of the field (e.g. 'based_near')
   # @param {string} url - The url for the autocompete search endpoint
   */
  setup (element, fieldName, url) {
    console.log(`setting up ${fieldName}`)
    switch (fieldName) {
      case 'work':
        new Work(
          element,
          url,
          element.data('id')
        )
        break
      case 'based_near':
        new LinkedData(element, url)
      default:
        new Default(element, url)
        break
    }
  }
}
