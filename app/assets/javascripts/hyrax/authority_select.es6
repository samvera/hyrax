/** Class for authority selection on an input field */
export default class AuthoritySelect {
    /**
     * Create an AuthoritySelect
     * @param {string} selectBox - The selector for the select box
     * @param {string} inputField - The selector for the input field
     */
    constructor(options) {
	this.selectBox = options.selectBox;
	this.inputField = options.inputField;
    }

    /**
     * Bind behavior for select box
     */
    selectBoxChange() {
	var selectBox = this.selectBox;
	var inputField = this.inputField;
	
	$(selectBox).on('change', function (data) {
	    var selectBoxValue = $(this).val();
	    $(inputField).each(function (data) { $(this).data('autocomplete-url', selectBoxValue);
						 
					       });
	    setupAutocomplete();
	});
    }
    /**
     * Create an observer to watch for added input elements
     */
    observeAddedElement() {
	var selectBox = this.selectBox;
	var inputField = this.inputField;
	
	
	var observer = new MutationObserver(function (mutations) {
	    mutations.forEach(function (mutation) {
		$(inputField).each(function (data) { $(this).data('autocomplete-url', $(selectBox).val()) });
		setupAutocomplete();
	    });
	});

	var config = { childList: true };
	observer.observe(document.body, config);
    }

    /**
     * Initialize bindings
     */
    initialize() {
	this.selectBoxChange();
	this.observeAddedElement();
	setupAutocomplete();
    }
}

/**
 * intialize the Hyrax autocomplete with the fields that you are using
 */
function setupAutocomplete() {
  Hyrax.autocomplete()
};
