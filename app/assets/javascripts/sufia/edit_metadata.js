Blacklight.onLoad(function() {
  function get_autocomplete_opts(field) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/authorities/generic_files/" + field, {
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
    return autocomplete_opts;
  }

    // there are two levels of vocabulary auto complete.
    // currently we have this externally hosted vocabulary
    // for geonames.  I'm not going to make these any easier
    // to implement for an external url (it's all hard coded)
    // because I'm guessing we'll get away from the hard coding
  var cities_autocomplete_opts = {
    source: function( request, response ) {
      $.ajax( {
        url: "http://ws.geonames.org/searchJSON",
        dataType: "jsonp",
        data: {
          featureClass: "P",
          style: "full",
          maxRows: 12,
          name_startsWith: request.term
        },
        success: function( data ) {        response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName
            };
          }));
        },
      });
    },
    minLength: 2
  };
  $("#generic_file_based_near").autocomplete(get_autocomplete_opts("location"));

  var autocomplete_vocab = new Object();

  autocomplete_vocab.url_var = ['subject', 'language'];   // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete
  autocomplete_vocab.add_btn_id = new Array(); // the id of the button pressed when adding an additional form element

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
    autocomplete_vocab.field_name.push('generic_file_' + autocomplete_vocab.url_var[i]);
    autocomplete_vocab.add_btn_id.push('additional_' + autocomplete_vocab.url_var[i] + '_submit');
    // add autocompletes to all inputs created
    $(".form-group.multi_value." + autocomplete_vocab.field_name[i]).find('input[type=text]')
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete( get_autocomplete_opts(autocomplete_vocab.url_var[i]) );

  }


  function setup_autocomplete(event) {
    var class_name = $.grep(event.target.className.split(" "),function( c ) {
          return c.indexOf('generic_file') == 0;
      })[0];
    // attach auto complete for location
    if (class_name == 'generic_file_based_near') {
      $(event.target).find('input[type=text]').autocomplete(get_autocomplete_opts("location"));
    }
    // attach other auto completes
    else if ( (index = $.inArray(class_name, autocomplete_vocab.field_name)) != -1 ) {
      $(event.target).find('input[type=text]').autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
    }
  }

  // add setup for autocompletes to multi value forms
  $('.multi_value.form-group').manage_fields({ add: setup_autocomplete });
});
