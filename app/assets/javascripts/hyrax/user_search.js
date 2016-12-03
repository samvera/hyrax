(function( $ ){

  $.fn.userSearch = function( options ) {
    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    var $container = this;

    return this.each(function() {
      $(this).select2( {
        placeholder: $(this).attr('value') || "Search for a user",
        minimumInputLength: 2,
        initSelection : function (element, callback) {
          var data = {id: element.val(), text: element.val()};
          callback(data);
        },
        ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
          url: "/users.json",
          dataType: 'json',
          data: function (term, page) {
            return {
              uq: term // search term
            };
          },
          results: function (data, page) { // parse the results into the format expected by Select2.
            // since we are using custom formatting functions we do not need to alter remote JSON data
            return {results: data};
          }
        },
      }).select2('data', null);
    });

  };
})( jQuery );
