import Default from './autocomplete/default';
import Work from './autocomplete/work';

export default class Autocomplete {
    constructor(options) {
	this.autocompleteFields = options.autocompleteFields;
    }
    // This is the initial setup for the form.
    setup() {
	$('[data-autocomplete]').each((index, value) => {
            let selector = $(value);
	    let autocompleteData = selector.data('autocomplete');
	    this.activateFields(autocompleteData,selector);
	});
    }
    // This activates autocomplete for added fields
    fieldAdded(cloneElem) {
	let selector = $(cloneElem);
	let autocompleteData = selector.data('autocomplete');
	this.activateFields(autocompleteData,selector);
    }
    autocomplete(field) {
	let fieldName = field.data('autocomplete');
	switch (fieldName) {
	case "work":
	    let user = field.data('user');
	    let id = field.data('id');
	    new Work(
		field,
		field.data('autocomplete-url'),
		user,
		id
	    );
	    break;
	default:
	    new Default(field, field.data('autocomplete-url'));
	    break;
	}
    }
    activateFields(autocompleteData, selector) {
	for (let field in this.autocompleteFields) {
	    if (autocompleteData === this.autocompleteFields[field]) {
		this.autocomplete(selector);
	    }
	}
    }
}
