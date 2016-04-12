export class RegistryEntry {
  /**
   * Initialize the registry
   * @param {Grant} grant the grant to display on the form
   * @param {Registry} registry the registry that holds this registry entry.
   */
  constructor(grant, registry, element, template) {
    this.grant = grant
    this.registry = registry
    this.element = element

    let row = this.createPermissionRow(grant, template);
    this.addHiddenPermField(row, grant);
    row.effect("highlight", {}, 3000);
  }

  createPermissionRow(grant, template_id) {
    let row = $(tmpl(template_id, grant));
    this.element.after(row);
    row.find('button').click(function () {
      row.remove();
    });

    return row;
  }

  addHiddenPermField(element, grant) {
      var prefix = this.registry.fieldPrefix(grant.index);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[type]',
          value: grant.type
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[name]',
          value: grant.name
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[access]',
          value: grant.access
      }).appendTo(element);
  }
}
