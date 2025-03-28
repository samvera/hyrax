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
      this.fileupload($.extend({
        maxChunkSize: 10000000,  // 10 MB chunk size
        autoUpload: true,
        url: '/uploads/',
        type: 'POST',
        dropZone: $(this).find('.dropzone'),
        add: function (e, data) {
          var that = this;
          $.post('/uploads/', { files: [data.files[0].name] }, function (result) {
            data.formData = {id: result.files[0].id};
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
