import RegistryEntry from './registry_entry'
export default class Registry {
  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
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
    element.find('[data-behavior="remove-relationship"]').on('click', (evt) => this.removeWork(evt))
  }

  // Return an index for the hidden field when adding a new row.
  // This makes the assumption that all the tr elements represent a work except
  // for the final one, which is the "add another" form
  nextIndex() {
      return this.element.find('tbody').children('tr').length - 1;
  }

  addWork(work) {
    work.index = this.nextIndex()
    this.items.push(new RegistryEntry(work, this, this.element.find('tr:last'), this.templateId))
    this.showSaveNote();
  }

  // removes a row that has been persisted
  removeWork(evt) {
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
    // TODO: we may want to reveal a note that changes aren't active until the work is saved
  }

}
