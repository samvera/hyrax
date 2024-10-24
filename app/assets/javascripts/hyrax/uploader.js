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
 * https://blueimp.net
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
        maxChunkSize: 10000000, // 10 MB
        autoUpload: true,
        url: '/uploads/',
        type: 'POST',
        dropZone: $(this).find('.dropzone'),
        add: function (e, data) {
          var that = this;
          $.getJSON('/uploads/resume_upload', {file: data.files[0].name}, function (result) {
            var file = result.file;
            if (file && file.size) {
              if (file.size >= data.files[0].size) {
                console.log('File already fully uploaded.');
                // Skip upload since the file is already uploaded
                return;
              }
              console.log('Resuming upload from byte: ', file.size);
              data.uploadedBytes = file.size;
            } else {
              console.log('No file found, starting new upload.');
              data.uploadedBytes = 0; // Start fresh
            }
            $.blueimp.fileupload.prototype.options.add.call(that, e, data);
          });
        }
        
      }, Hyrax.config.uploader, options))
      .on('fileuploadadded', function (e, data) {
        $(e.currentTarget).find('button.cancel').removeAttr("hidden");
      });

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

