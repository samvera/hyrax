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
        // xhrFields: {withCredentials: true},              // to send cross-domain cookies
        // acceptFileTypes: /(\.|\/)(png|mov|jpe?g|pdf)$/i, // not a strong check, just a regex on the filename
        // limitMultiFileUploadSize: 500000000, // bytes
        autoUpload: true,
        url: '/uploads/',
        type: 'POST',
        dropZone: $(this).find('.dropzone')
      }, Hyrax.config.uploader, options))
      .bind('fileuploadadded', function (e, data) {
        $(e.currentTarget).find('button.cancel').prop('hidden', false);
      });

      $(document).bind('dragover', function(e) {
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
