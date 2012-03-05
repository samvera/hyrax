$(function() {

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
});
