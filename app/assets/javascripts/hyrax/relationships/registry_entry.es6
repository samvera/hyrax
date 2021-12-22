import ConfirmRemoveDialog from 'hyrax/relationships/confirm_remove_dialog'

export default class RegistryEntry {
    /**
     * Initialize the registry entry
     * @param {Resource} resource the resource to display on the form
     * @param {Registry} registry the registry that holds this registry entry.
     * @param {String} template identifer of the new row template.
     */
    constructor(resource, registry, template) {
        this.resource = resource
        this.registry = registry
        this.view = this.createView(resource, template);
        this.destroyed = false
        //this.view.effect("highlight", {}, 3000);
    }

    export() {
      return { 'id': this.resource.id, '_destroy': this.destroyed }
    }

    // Add a row that has not been persisted
    createView(resource, templateId) {
        let row = $(tmpl(templateId, resource))
        let removeButton = row.find('[data-behavior="remove-relationship"]')
        removeButton.click((e) => {
          e.preventDefault()
          var dialog = new ConfirmRemoveDialog(removeButton.data('confirmText'),
                                               removeButton.data('confirmCancel'),
                                               removeButton.data('confirmRemove'),
                                               () => this.removeResource(e));
          dialog.launch();
        });
        return row;
    }

    // Hides the row and adds a _destroy=true field to the form
    removeResource(evt) {
       evt.preventDefault();
       let button = $(evt.target);
       this.view.prop('hidden', true); // do not show the block
       this.destroyed = true
       this.registry.showSaveNote();
    }
}
