//= require sufia/uploader
// This file is the default initialization of the fileupload.  If you want to call
// sufiaUploader with other options (like afterSubmit), then override this file.
Blacklight.onLoad(function() {
  $('#fileupload').sufiaUploader();
});
