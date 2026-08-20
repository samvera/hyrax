//= require hyrax/uploader
// This file is the default initialization of the file upload widgets. If you
// want to initialize Hyrax.Uploader with other options, override this file.
Blacklight.onLoad(function() {
  // expose the uploader for view-level initializers and overrides
  window.Hyrax = window.Hyrax || {};
  if (!window.Hyrax.Uploader) {
    window.Hyrax.Uploader = require('hyrax/uploader').Uploader;
  }

  var main = document.getElementById('fileupload');
  if (main && !main.hyraxUploader) { new Hyrax.Uploader(main, {}); }

  var logo = document.getElementById('fileuploadlogo');
  if (logo && !logo.hyraxUploader) {
    new Hyrax.Uploader(logo, { rowTemplate: 'hyrax-upload-row-logo' });
  }
});
