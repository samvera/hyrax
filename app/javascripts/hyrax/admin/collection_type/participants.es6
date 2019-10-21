

export default class {
  // Adds autocomplete to the user search function and enables the
  // "Allow all registered users" button.
  constructor(elem) {
    this.userField = elem.find('#user-participants-form input[type=text]')
  }

  setup() {
    this.userField.userSearch()
  }
}
