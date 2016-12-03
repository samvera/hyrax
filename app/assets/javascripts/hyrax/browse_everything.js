//= require browse_everything

// Show the files in the queue
Blacklight.onLoad( function() {
  $('#browse-btn').browseEverything()
  .done(function(data) {
    var evt = { isDefaultPrevented: function() { return false; } };
    var files = $.map(data, function(d) { return { name: d.file_name, size: d.file_size, id: d.url } });
    $.blueimp.fileupload.prototype.options.done.call($('#fileupload').fileupload(), evt, { result: { files: files }});
  })
});
