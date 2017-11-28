import RegistryEntry from './registry_entry'
export default class Registry {
  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container.
   *                         must be a table with a tbody element.
   * @param {String} object_name the name of the object, for constructing form fields (e.g. 'generic_work')
   * @param {String} templateId the the identifier of the template for the added elements
   */
  constructor(element, objectName, propertyName, templateId) {
    this.objectName = objectName
    this.propertyName = propertyName

    this.templateId = templateId
    this.items = []
    this.element = element

    // the remove button is only on preexisting grants
    element.find('[data-behavior="remove-relationship"]').on('click', (evt) => this.removeResource(evt))
  }

  // Return an index for the hidden field when adding a new row.
  // A large random will probably avoid collisions.
  nextIndex() {
    return Math.floor(Math.random() * 1000000000000000)
  }

  // Adds the resource to the first row of the tbody
  addResource(resource) {
      resource.index = this.nextIndex()
      this.items.push(new RegistryEntry(resource, this, this.element, this.templateId))
      this.showSaveNote();
  }

  // removes a row that has been persisted
  removeResource(evt) {
     evt.preventDefault();
     let button = $(evt.target);
     let container = button.closest('tr');
     container.addClass('hidden'); // do not show the block
     this.addDestroyField(container, button.attr('data-index'));
     this.showSaveNote();
  }

  addDestroyField(element, index) {
      $('<input>').attr({
          type: 'hidden',
          name: `${this.fieldPrefix(index)}[_destroy]`,
          value: 'true'
      }).appendTo(element);
  }

  fieldPrefix(counter) {
    return `${this.objectName}[${this.propertyName}][${counter}]`
  }

  showSaveNote() {
    // TODO: we may want to reveal a note that changes aren't active until the resource is saved
  }

}
