export class Work {
  // Autocomplete for finding possible related works (child and parent).
  constructor(element, url, user, id) {
    this.url = url;
    this.user = user;
    this.work_id = id;
    element.autocomplete(this.options());
  }

  options() {
    return {
      minLength: 2,
      source: ( request, response ) => {
        $.getJSON(this.url, {
          q: request.term,
          id: this.work_id,
          user: this.user
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
