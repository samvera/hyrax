export class Location {
  constructor(element, url) {
    this.url = url
    element.autocomplete(this.options());
  }

  options() {
    return {
      minLength: 2,
      source: ( request, response ) => {
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
      }
    };
  }
}
