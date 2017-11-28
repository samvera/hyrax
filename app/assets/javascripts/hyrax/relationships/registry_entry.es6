export default class RegistryEntry {
    /**
     * Initialize the registry entry
     * @param {Resource} resource the resource to display on the form
     * @param {Registry} registry the registry that holds this registry entry.
     * @param {jQuery} element insert the template before this element
     * @param {String} template identifer of the new row template.
     */
    constructor(resource, registry, element, template) {
        this.resource = resource
        this.registry = registry
        this.element = element

        let row = this.createRow(resource, template);
        this.addHiddenField(row, resource);
        row.effect("highlight", {}, 3000);
    }

    // Add a row that has not been persisted
    createRow(resource, templateId) {
        let row = $(tmpl(templateId, resource));
        this.element.prepend(row);
        row.find('[data-behavior="remove-relationship"]').click(function () {
            row.remove();
        });

        return row;
    }

    addHiddenField(element, resource) {
        var prefix = this.registry.fieldPrefix(resource.index);
        $('<input>').attr({
            type: 'hidden',
            name: prefix + '[id]',
            value: resource.id
        }).appendTo(element);
    }
}
