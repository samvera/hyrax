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

});
