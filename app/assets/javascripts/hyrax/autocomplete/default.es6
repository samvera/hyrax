export default class Default {
  constructor(element, url) {
    this.url = url;
    element.autocomplete(this.options(element));
  }
  options(element) {
    return {
      minLength: 2,
      source: (request, response) => {
        $.getJSON(this.url, {
          q: request.term
        }, response );
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      },
      select: function() {
	  if (element.data('autocomplete-read-only') === true) {
           element.attr('readonly', true);
	}
      }
	
    };
  }
}
