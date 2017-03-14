import Registry from './registry'
import Work from './work'

export default class RelationshipsControl {

  /**
   * Initializes the class in the context of an individual table element
   * @param {jQuery} element the table element that this class represents
   * @param {String} property the property to submit
   * @param {String} templateId the template identifier for new rows
   */
  constructor(element, property, templateId) {
    this.element = element
    this.registry = new Registry(this.element, this.element.data('paramKey'), property, templateId)

    this.input = this.element.find("[data-autocomplete='work']")
    this.warning = this.element.find(".message.has-warning")
    this.addButton = this.element.find("[data-behavior='add-relationship']")
    this.errors = null
    this.bindAddButton();
  }

  validate() {
    if (this.input.val() === "") {
      this.errors = ['ID cannot be empty.']
    }
  }

  isValid() {
    this.validate()
    return this.errors === null
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    this.addButton.on("click", () => this.attemptToAddRow())
  }

  attemptToAddRow() {
      // Display an error when the input field is empty, or if the work ID is already related,
      // otherwise clone the row and set appropriate styles
      if (this.isValid()) {
        this.addRow()
      } else {
        this.setWarningMessage(this.errors.join(', '))
      }
  }

  addRow() {
    this.hideWarningMessage()
    let data = this.searchData()
    this.registry.addWork(new Work(data.id, data.text))

    // finally, empty the "add" row input value
    this.clearSearch();
  }

  searchData() {
    return this.input.select2('data')
  }

  clearSearch() {
    this.input.select2("val", '');
  }

  /**
   * Set the warning message related to the appropriate row in the table
   * @param {String} message the warning message text to set
   */
  setWarningMessage(message) {
    this.warning.text(message).removeClass("hidden");
  }

  /**
   * Hide the warning message on the appropriate row
   */
  hideWarningMessage(){
    this.warning.addClass("hidden");
  }
}
