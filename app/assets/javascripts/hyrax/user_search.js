(function( $ ){

  $.fn.userSearch = function() {
    return this.each(function() {
      $(this).select2( {
        placeholder: $(this).attr("value") || "Search for a user",
        minimumInputLength: 2,
        id: function(object) {
          return object.user_key;
        },
        initSelection: function(element, callback) {
          var data = {
            id: element.val(),
            text: element.val()
          };
          callback(data);
        },
        ajax: { // Use the jQuery.ajax wrapper provided by Select2
          url: "/users.json",
          dataType: "json",
          data: function (term, page) {
            return {
              uq: term // Search term
            };
          },
          results: function(data, page) {
            return { results: data.users };
          }
        },
      }).select2('data', null);
    });

  };
})( jQuery );
