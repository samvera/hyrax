$(function() {

  var subject_autocomplete_opts = {
    minLength: 1,
    source: function( request, response ) {
      $.getJSON( "/authorities/generic_files/subject", {
        //term: extractLast( request.term )
        q: request.term 
      }, response );
    },
    focus: function() {
      // prevent value inserted on focus
      return false;
    }
    /*,
    select: function( event, ui ) {
      $("#selectedSubjects").append("<div class = 'selectedsubject'>" + ui.item.label+"<img id='killSubject' style='position:relative; left:10px' src='images/close_icon.gif'/><div id='hiddenId' style='display:none'>"+ui.item.value+"</div></div>");                
      $(this).val("");
      return false;
    }*/
  }

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
              value: item.name
            }
          }));
        }
      });
    },
    minLength: 2,
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
    else if (this.id == 'additional_subject_submit') {
      cloneElem.find('input[type=text]').autocomplete(subject_autocomplete_opts);
    }

    $('#'+newId).append(cloneElem);
    cloneElem.find('input[type=text]').focus();
    return false;
  });

  $('.icon-plus').click(function() {
    //this.id format: "expand_id:NNNNNNNNNN"
    var a = this.id.split("expand_id_");
    if (a.length > 1)
    {
      docId = a[1]
      $("#detail_id_"+docId).toggle();
      if( $("#detail_id_"+docId).is(":hidden") ) {
        $("#expand_id_"+docId).attr("class", "icon-plus");
      }
      else {
        $("#expand_id_"+docId).attr("class", "icon-minus");
      }
    }
  })

  // autocompletes
  $("#generic_file_subject")
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete(subject_autocomplete_opts);

  $("#generic_file_based_near").autocomplete(cities_autocomplete_opts);


});
