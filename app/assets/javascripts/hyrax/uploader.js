//= require fileupload/tmpl
//= require fileupload/jquery.iframe-transport
//= require fileupload/jquery.fileupload.js
//= require fileupload/jquery.fileupload-process.js
//= require fileupload/jquery.fileupload-validate.js
//= require fileupload/jquery.fileupload-ui.js
//
/*
 * jQuery File Upload Plugin JS Example
 * https://github.com/blueimp/jQuery-File-Upload
 *
 * Copyright 2010, Sebastian Tschan
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 */

(function( $ ){
  'use strict';

  $.fn.extend({
    hyraxUploader: function( options ) {
      // Initialize our jQuery File Upload widget.
      this.fileupload($.extend({
        maxChunkSize: 5000000,  // 5 MB chunk size
        autoUpload: true,
        url: '/uploads/',
        type: 'POST',
        dropZone: $(this).find('.dropzone'),
        
        // Override the add function to handle resume or fresh upload
        add: function (e, data) {
          var that = this;

          // Check with the server if a partial upload exists for this file
          $.getJSON('/uploads/resume_upload', { file: data.files[0].name }, function (result) {
            var file = result.file;

            // If file exists and is partially uploaded, resume from the correct byte
            if (file && file.size && file.size < data.files[0].size) {
              console.log('Resuming upload from byte: ', file.size);
              data.uploadedBytes = file.size;

            // If file exists and is fully uploaded, force a new upload
            } else if (file && file.size >= data.files[0].size) {
              console.log('File already fully uploaded, starting a new upload.');
              data.uploadedBytes = 0;

            // Otherwise, this is a fresh upload
            } else {
              console.log('No file found, starting new upload.');
              data.uploadedBytes = 0;
            }

            // Proceed with the upload
            $.blueimp.fileupload.prototype.options.add.call(that, e, data);
          });
        },

        // Handle failed uploads and send a DELETE request to remove incomplete files
        fail: function (e, data) {
          console.log('Upload failed or aborted. Deleting incomplete upload...');
          
          // Make a DELETE request to remove incomplete uploads
          $.ajax({
            url: '/uploads/delete_incomplete',
            type: 'DELETE',
            contentType: 'application/json',
            data: JSON.stringify({ file_name: data.files[0].name }),
            success: function (response) {
              console.log('Incomplete upload deleted successfully.');

              // Remove the file row from the upload list in the UI
              $(data.context).fadeOut(function () {
                $(this).remove();  // Remove the row from the UI
              });
              
              // Alternatively, mark it as "Cancelled"
              // $(data.context).find('.status').text('Cancelled').addClass('text-danger');
            },
            error: function (xhr, status, error) {
              console.error('Failed to delete incomplete upload:', error);

              $(data.context).fadeOut(function () {
                $(this).remove();  // Remove the row from the UI
              });
            }
          });
        }
        
      }, Hyrax.config.uploader, options))
      .on('fileuploadadded', function (e, data) {
        $(e.currentTarget).find('button.cancel').removeAttr("hidden");
      });

      // Add the drag and drop event handlers for visual feedback
      $(document).on('dragover', function(e) {
        var dropZone = $('.dropzone'),
            timeout = window.dropZoneTimeout;
        if (!timeout) {
          dropZone.addClass('in');
        } else {
          clearTimeout(timeout);
        }
        var found = false,
            node = e.target;
        do {
          if (node === dropZone[0]) {
            found = true;
            break;
          }
          node = node.parentNode;
        } while (node !== null);
        if (found) {
          dropZone.addClass('hover');
        } else {
          dropZone.removeClass('hover');
        }
        window.dropZoneTimeout = setTimeout(function () {
          window.dropZoneTimeout = null;
          dropZone.removeClass('in hover');
        }, 100);
      });
    }
  });
})(jQuery);
