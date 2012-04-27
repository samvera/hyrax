$(function() {
 
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
        success: function( data ) {
          response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
            }
          }));
        }
      });
    },
    minLength: 2,
  }
  $("#generic_file_based_near").autocomplete(cities_autocomplete_opts);


  function get_autocomplete_opts(field)
  {
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
      }/*
      select: function( event, ui ) {
        $("#selectedSubjects").append("<div class = 'selectedsubject'>" + ui.item.label+"<img id='killSubject' style='position:relative; left:10px' src='images/close_icon.gif'/><div id='hiddenId' style='display:none'>"+ui.item.value+"</div></div>");                
        $(this).val("");
        return false;
      }*/
    }
    return autocomplete_opts;
  }

  var autocomplete_vocab = new Object();
  
  autocomplete_vocab.url_var =      ['subject', 'language', 'tag'];   // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete
  autocomplete_vocab.add_btn_id = new Array(); // the id of the button pressed when adding an additional form element 

  // loop over the autocomplete fields and attach the 
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++) 
  {
    autocomplete_vocab.field_name.push('generic_file_' + autocomplete_vocab.url_var[i]);
    autocomplete_vocab.add_btn_id.push('additional_' + autocomplete_vocab.url_var[i] + '_submit');
    // autocompletes
    $("#" + autocomplete_vocab.field_name[i])
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete( get_autocomplete_opts(autocomplete_vocab.url_var[i]) );
    
  }

  /* 
   * adds a new file input for ingest
   */
  $('#additional_files_submit').click(function() {
    var a = $('#upload_field_1').clone();
    var currentIdNum = $('#file_count').attr("value");
    var nextIdNum = parseInt(currentIdNum)+1;
    a.attr("id", "upload_field_" + nextIdNum);
    var newFileInput = a.find('#Filedata_'); 
    newFileInput.attr("id", "Filedata_"+nextIdNum);
    $('#additional_files').append(a);
    $('#file_count').attr("value", nextIdNum);
    return false; 
  })

  $('.adder').click(function() {
    //this.id = additional_N_submit
    //id for element to clone = additional_N_clone
    //id for element to append to = additional_N_elements
    var cloneId = this.id.replace("submit", "clone");
    var newId = this.id.replace("submit", "elements");
    var cloneElem = $('#'+cloneId).clone();

    //remove the button before adding the input
    //we don't want a button on each element being appended
    cloneElem.find('#'+this.id).remove();

    //clear out the value for the element being appended
    //so the new element has a blank value
    cloneElem.find('input[type=text]').attr("value", "");

    // should we attach an auto complete based on the input
    if (this.id == 'additional_based_near_submit') {
      cloneElem.find('input[type=text]').autocomplete(cities_autocomplete_opts);
    }
    else if ( (index = $.inArray(this.id, autocomplete_vocab.add_btn_id)) != -1 ) {
      cloneElem.find('input[type=text]').autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
    }

    $('#'+newId).append(cloneElem);
    cloneElem.find('input[type=text]').focus();
    return false;
  });

  $('.icon-plus').click(function() {
    //this.id format: "expand_NNNNNNNNNN"
    var a = this.id.split("expand_");
    if (a.length > 1)
    {
      docId = a[1]
      $("#detail_"+docId).toggle();
      if( $("#detail_"+docId).is(":hidden") ) {
        $("#expand_"+docId).attr("class", "icon-plus");
      }
      else {
        $("#expand_"+docId).attr("class", "icon-minus");
      }
    }
  })

  $('#add_descriptions').click(function() {
      $('#more_descriptions').show();
  });

});
