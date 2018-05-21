//= require hyrax/uploader
// This file is the default initialization of the fileupload.  If you want to call
// hyraxUploader with other options (like afterSubmit), then override this file.
Blacklight.onLoad(function() {
  var options = {};
  $('#fileupload').hyraxUploader(options);
  $('#fileuploadlogo').hyraxUploader({downloadTemplateId: 'logo-template-download'});
  $("#new_generic_work, #new_batch_upload_item, .edit_generic_work").on('submit', function(event) {
    $(".panel-footer").toggleClass("hidden");
  });
});
