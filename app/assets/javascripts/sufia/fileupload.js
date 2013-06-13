//= require fileupload/tmpl
//= require fileupload/jquery.iframe-transport
//= require fileupload/jquery.fileupload.js
//= require fileupload/jquery.fileupload-ui.js
//= require fileupload/locale.js
//
/*jslint nomen: true */
/*global $ */

var filestoupload =0;      
var files_done =0;      
var error_string ='';      
//200 MB  max file size 
var max_file_size = 200000000;
var max_file_size_str = "200 MB";
//500 MB max total upload size
var max_total_file_size = 500000000;
var max_file_count = 100;
var max_total_file_size_str = "500 MB";
var first_file_after_max = ''; 

$(function () {
    'use strict';

    // Initialize the jQuery File Upload widget:
    $('#fileupload').fileupload();
    
    // Enable iframe cross-domain access via redirect option:
    $('#fileupload').fileupload(
        'option',
        'redirect',
        window.location.href.replace(
            /\/[^\/]*$/,
            '/cors/result.html?%s'
        )
    );

    $('#fileupload').fileupload(
        'option',
        'acceptFileTypes',
        /^[^\.].*$/i
    );

    $('#fileupload').bind("fileuploadstop", function(){
      if ((files_done == filestoupload)&&(files_done >0)){
         var loc = $("#redirect-loc").html()
         $(location).attr('href',loc);
      } else if (error_string.length > 0){
        // an error occured       
         if (files_done == 0) {
            $("#fail").fadeIn('slow')
         } else {
            $("#partial_fail").fadeIn('slow')
         }          
         $("#errmsg").html(error_string);
         $("#errmsg").fadeIn('slow');
      }
    }); 

    // count the number of uploaded files to send to edit
    $('#fileupload').bind("fileuploadadd", function(e, data){
      filestoupload++;
      if ( $('#terms_of_service').is(':checked') )$('#main_upload_start').attr('disabled', false);
    });
    
    
    // check the validation on if the file type is not accepted just click cancel for the user as we do not want them to see all the hidden files
    $('#fileupload').bind("fileuploadadded", function(e, data){
        if (data.files[0].error == 'acceptFileTypes'){
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
        }
        var total_sz = parseInt($('#total_upload_size').val()) + data.files[0].size;
        // is file size too big
        if (data.files[0].size > max_file_size) {
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
          $("#errmsg").html(data.files[0].name + " is too big. No files over " + max_file_size_str + " can be uploaded.");
          $("#errmsg").fadeIn('slow');
        }
        // cumulative upload file size is too big
        else if( total_sz > max_total_file_size) {
          if (first_file_after_max == '') first_file_after_max = data.files[0].name;
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
          $("#errmsg").html("All files selected from " + first_file_after_max + " and after will not be uploaded because your total upload is too big. You may not upload more than " + max_total_file_size_str + " in one upload.");
          $("#errmsg").fadeIn('slow');
        }
        else if( filestoupload > max_file_count) {
          if (first_file_after_max == '') first_file_after_max = data.files[0].name;
          $($('#fileupload .files .cancel button')[data.context[0].rowIndex]).click(); 
          $("#errmsg").html("All files selected from " + first_file_after_max + " and after will not be uploaded because your total number of files is too big. You may not upload more than " + max_file_count + " files in one upload.");
          $("#errmsg").fadeIn('slow');
        }
        else {
          $('#total_upload_size').val( parseInt($('#total_upload_size').val()) + data.files[0].size );
        }
              
    });

    // count the number of files completed and ready to send to edit                          
    $('#fileupload').bind("fileuploaddone", function(e, data){
      var file = ($.isArray(data.result) && data.result[0]) || {error: 'emptyResult'};
      if (!file.error) {
        files_done++;     
      } else {
        if (error_string.length > 0) {
          error_string += '<br/>';
        }
        error_string += file.error;
      }
    });


    // data. takes the contextual values in the file your uploading
    // so and assign them to a value in the form that is being uploaded
    // much is based off https://github.com/blueimp/jQuery-File-Upload/wiki/How-to-submit-additional-Form-Data
    $('#fileupload').bind('fileuploadsubmit', function (e, data) {
      //var inputs = data.context.find(':input');
      //$('#fileupload').formData = inputs.serializeArray();
      //data.form = inputs.serializeArray
      //$('#relative_path').val(inputs[0].value); 
      $('#relative_path').val(data.files[0].webkitRelativePath)
    });


    // on fail if abort (aka cancel) decrease the number of uploaded files to send
    $('#fileupload').bind("fileuploadfail", function(e, data){ 
      if (data.errorThrown == 'abort') {
         filestoupload--;
         if ((files_done == filestoupload)&&(files_done >0)){
             var loc = $("#redirect-loc").html()+"?file_count="+filestoupload
             $(location).attr('href',loc);
         }
         $('#total_upload_size').val( parseInt($('#total_upload_size').val()) - data.files[0].size );
         
      } else {
       if (error_string.length > 0) {
          error_string +='<br/>';
       }
       error_string +=data.errorThrown+": "+data.textStatus;
      }
    });

    // Open download dialogs via iframes,
    // to prevent aborting current uploads:
    $(document).on('click', '#fileupload .files a:not([target^=_blank])', function (e) {
        e.preventDefault();
        $('<iframe style="display:none;"></iframe>')
            .prop('src', this.href)
            .appendTo('body');
    });
});
