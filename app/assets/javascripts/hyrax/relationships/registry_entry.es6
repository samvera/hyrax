export default class RegistryEntry {
  /**
   * Initialize the registry entry
   * @param {Work} work the work to display on the form
   * @param {Registry} registry the registry that holds this registry entry.
   * @param {jQuery} element a place to insert the new row
   * @param {String} template identifer of the new row template.
   */
  constructor(work, registry, element, template) {
    this.work = work
    this.registry = registry
    this.element = element

    let row = this.createRow(work, template);
    this.addHiddenField(row, work);
    row.effect("highlight", {}, 3000);
  }

  // Remove a row that has not been persisted
  createRow(work, templateId) {
    let row = $(tmpl(templateId, work));
    this.element.before(row);
    row.find('[data-behavior="remove-relationship"]').click(function () {
      row.remove();
    });

    return row;
  }

  addHiddenField(element, work) {
      var prefix = this.registry.fieldPrefix(work.index);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[id]',
          value: work.id
      }).appendTo(element);
  }
}
