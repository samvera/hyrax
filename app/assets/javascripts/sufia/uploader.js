//= require fileupload/tmpl
//= require fileupload/jquery.iframe-transport
//= require fileupload/jquery.fileupload.js
//= require fileupload/jquery.fileupload-process.js
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

/* global $, window */

//200 MB  max file size
var max_file_size = 200000000;
var max_file_size_str = "200 MB";
//500 MB max total upload size
var max_total_file_size = 500000000;
var max_file_count = 100;
var max_total_file_size_str = "500 MB";
var first_file_after_max = '';
var filestoupload =0;

(function( $ ){
    'use strict';

    $.fn.sufiaUploader = function( options ) {
        // Initialize the jQuery File Upload widget:
        $('#fileupload').fileupload({
            // Uncomment the following to send cross-domain cookies:
            //xhrFields: {withCredentials: true},
            url: '/uploads/',
            type: 'POST'
        });

        // Enable iframe cross-domain access via redirect option:
        $('#fileupload').fileupload(
            'option',
            'redirect',
            window.location.href.replace(
                /\/[^\/]*$/,
                '/cors/result.html?%s'
            )
        );
    };
})(jQuery);
