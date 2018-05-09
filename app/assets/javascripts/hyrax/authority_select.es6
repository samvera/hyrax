import Autocomplete from 'hyrax/autocomplete'

/** Class for authority selection on an input field */
export default class AuthoritySelect {
    /**
     * Create an AuthoritySelect
     * @param {Editor} editor - The parent container
     * @param {string} selectBox - The selector for the select box
     * @param {string} inputField - The selector for the input field
     */
    constructor(options) {
    	this.selectBox = options.selectBox
    	this.inputField = options.inputField
    	this.selectBoxChange();
    	this.observeAddedElement();
    	this.setupAutocomplete();
    }

    /**
     * Bind behavior for select box
     */
    selectBoxChange() {
      	var selectBox = this.selectBox;
      	var inputField = this.inputField;
        var _this2 = this
      	$(selectBox).on('change', function(data) {
      	    var selectBoxValue = $(this).val();
      	    $(inputField).each(function (data) {
              $(this).data('autocomplete-url', selectBoxValue);
      	       _this2.setupAutocomplete()
            });
      	});
    }

    /**
     * Create an observer to watch for added input elements
     */
    observeAddedElement() {
      	var selectBox = this.selectBox;
      	var inputField = this.inputField;
        var _this2 = this

      	var observer = new MutationObserver((mutations) => {
      	    mutations.forEach((mutation) => {
      		      $(inputField).each(function (data) {
                  $(this).data('autocomplete-url', $(selectBox).val())
      		        _this2.setupAutocomplete();
                });
      	    });
      	});

      	var config = { childList: true };
      	observer.observe(document.body, config);
    }

    /**
     * intialize the Hyrax autocomplete with the fields that you are using
     */
    setupAutocomplete() {
      var inputField = $(this.inputField);
      var autocomplete = new Autocomplete()
      autocomplete.setup(inputField, inputField.data('autocomplete'), inputField.data('autocompleteUrl'))
    }
}
