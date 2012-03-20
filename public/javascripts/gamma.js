$(function() {

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

  /*
   * adds a dropdown to include more metadata 
   * on ingest
   */
  $('#additional_md_submit').click(function() {
    var md_inputs = $('#extra_description_1').clone();
    var currentIdNum = $('#extra_description_count').attr("value");
    var nextIdNum = parseInt(currentIdNum)+1;
    md_inputs.attr("id", "extra_description_" + nextIdNum); 
    var newSelect = md_inputs.find('#metadata_key_1');
    var newInput = md_inputs.find('#metadata_value_1');
    newSelect.attr("id", "metadata_key_"+nextIdNum);
    newSelect.attr("name", "metadata_key_"+nextIdNum);
    newInput.attr("id", "metadata_value_"+nextIdNum);
    newInput.attr("name", "metadata_value_"+nextIdNum);
    newInput.attr("value", "");
    $('#more_descriptions').append(md_inputs);
    $('#extra_description_count').attr("value", nextIdNum);
    return false;
  })

  $('#upload_submit').click(function() {
    //loop over additional metadata elements and create new 
    //form elements
    var addedElements = parseInt( $('#extra_description_count').attr("value") );
    for(var i=1; i <= addedElements; i++) 
    {
      var k = $("#metadata_key_"+i).val();
      var v = $("#metadata_value_"+i).val();
      $('<input>').attr({
        'type': 'hidden',
        'name': 'generic['+k+']',
        'value': v,
      }).appendTo('form');
    }
    
  })


  $('.icon-plus').click(function() {
    //this.id format: "expand_id:NNNNNNNNNN"
    var a = this.id.split("expand_id_");
    if (a.length > 1)
    {
      docId = a[1]
      $("#detail_id_"+docId).toggle();
      if( $("#detail_id_"+docId).is(":hidden") ) 
      {
        $("#expand_id_"+docId).attr("class", "icon-plus");
      }
      else
      {
        $("#expand_id_"+docId).attr("class", "icon-minus");
      }
    }
  })
var availableTags = [
      "ActionScript",
      "AppleScript",
      "Asp",
      "BASIC",
      "C",
      "C++",
      "Clojure",
      "COBOL",
      "ColdFusion",
      "Erlang",
      "Fortran",
      "Groovy",
      "Haskell",
      "Java",
      "JavaScript",
      "Lisp",
      "Perl",
      "PHP",
      "Python",
      "Ruby",
      "Scala",
      "Scheme"
    ];
/*
    $( "#generic_file_subject" ).autocomplete({
      source: availableTags
    });
*/
  $("input#generic_file_subject")
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete({
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
            }/*,
            select: function( event, ui ) {
             $("#selectedSubjects").append("<div class = 'selectedsubject'>" + ui.item.label+"<img id='killSubject' style='position:relative; left:10px' src='images/close_icon.gif'/><div id='hiddenId' style='display:none'>"+ui.item.value+"</div></div>");                
             $(this).val("");
             return false;
            }*/
        });

});
