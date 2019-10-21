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
    element.closest('form').on('submit', (evt) => {
        this.serializeToForm()
    });
  }

  // Return an index for the hidden field when adding a new row.
  // A large random will probably avoid collisions.
  nextIndex() {
      return Math.floor(Math.random() * 1000000000000000)
  }

  export() {
      return this.items.map(item => item.export())
  }

  serializeToForm() {
      this.export().forEach((item, index) => {
          this.addHiddenField(index, 'id', item.id)
          this.addHiddenField(index, '_destroy', item['_destroy'])
      })
  }

  addHiddenField(index, key, value) {
      $('<input>').attr({
          type: 'hidden',
          name: `${this.fieldPrefix(index)}[${key}]`,
          value: value
      }).appendTo(this.element);
  }

  // Adds the resource to the first row of the tbody
  addResource(resource) {
      resource.index = this.nextIndex()
      let entry = new RegistryEntry(resource, this, this.templateId)
      this.items.push(entry)
      this.element.prepend(entry.view)
      this.showSaveNote()
  }

  fieldPrefix(counter) {
    return `${this.objectName}[${this.propertyName}][${counter}]`
  }

  showSaveNote() {
    // TODO: we may want to reveal a note that changes aren't active until the resource is saved
  }
}
