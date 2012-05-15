/*
 * jQuery File Upload Plugin JS Example 5.0.2
 * https://github.com/blueimp/jQuery-File-Upload
 *
 * Copyright 2010, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://creativecommons.org/licenses/MIT/
 */

/*jslint nomen: true */
/*global $ */

var filestoupload =0;      
var files_done =0;      
var error_string ='';      

$(function () {
    'use strict';

    // Initialize the jQuery File Upload widget:
    $('#fileupload').fileupload();
    $('#fileupload').bind("fileuploadstop", function(){
      if ((files_done == filestoupload)&&(files_done >0)){
         //var loc = $("#redirect-loc").html()+"?file_count="+filestoupload
         var loc = $("#redirect-loc").html()
         $(location).attr('href',loc);
      // some error occured       
      } else if (error_string.length > 0){
         if (files_done == 0) {
            $("#fail").fadeIn('slow')
         } else {
            $("#partial_fail").fadeIn('slow')
         }          
         $("#errmsg").html(error_string)
         $("#errmsg").fadeIn('slow')
      }
    }); 
    
    // count the number of uploaded files to send to edit
    $('#fileupload').bind("fileuploadadd", function(e, data){
      filestoupload++;
    });

    // count the number of files completed and ready to send to edit                          
    $('#fileupload').bind("fileuploaddone", function(e, data){
     var file = ($.isArray(data.result) && data.result[0]) || {error: 'emptyResult'};
     if (!file.error) {
       files_done++;     
     }else {
       if (error_string.length > 0) {
          error_string +='<br/>';
       }
       error_string +=file.error;
     }
    
    });

    // on fail if abort (aka cancel) decrease the number of uploaded files to send
    $('#fileupload').bind("fileuploadfail", function(e, data){ 
      if (data.errorThrown == 'abort') {
         filestoupload--;
         if ((files_done == filestoupload)&&(files_done >0)){
             var loc = $("#redirect-loc").html()+"?file_count="+filestoupload
             $(location).attr('href',loc);
         }
      } else {
       if (error_string.length > 0) {
          error_string +='<br/>';
       }
       error_string +=data.errorThrown+": "+data.textStatus;
      }
    });
    
    
    // Load existing files:
    $.getJSON($('#fileupload form').prop('action'), function (files) {
        var fu = $('#fileupload').data('fileupload');
        fu._adjustMaxNumberOfFiles(-files.length);
        fu._renderDownload(files)
            .appendTo($('#fileupload .files'))
            .fadeIn(function () {
                // Fix for IE7 and lower:
                $(this).show();
            });
    });

    // Open download dialogs via iframes,
    // to prevent aborting current uploads:
    $('#fileupload .files a:not([target^=_blank])').live('click', function (e) {
        e.preventDefault();
        $('<iframe style="display:none;"></iframe>')
            .prop('src', this.href)
            .appendTo('body');
    });

});
