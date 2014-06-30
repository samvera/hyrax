Blacklight.onLoad(function() {
  // toggle button on or off based on boxes being clicked
  $(".batch_document_selector, .batch_document_selector_all").bind('click', function(e) {
    var n = $(".batch_document_selector:checked").length;
    if (n>0 || $('input#check_all')[0].checked) {
      $('.sort-toggle').hide();
    } else {
      $('.sort-toggle').show();
    }
  });

  // show/hide more information on the dashboard when clicking
  // plus/minus
  $('.glyphicon-chevron-right').on('click', function() {
  var button = $(this);
  //this.id format: "expand_NNNNNNNNNN"
  var array = this.id.split("expand_");
  if (array.length > 1) {
    var docId = array[1];
    $("#detail_" + docId + " .expanded-details").slideToggle();
    button.toggleClass('glyphicon-chevron-right glyphicon-chevron-down');
  }
  return false;
  });

});
