Blacklight.onLoad(function () {

  // Remove from collection button clicked
  $('#collection-controls').find('.remove-from-collection-button').on('click', function (e) {
    e.preventDefault();
    $('#collection-remove-from-collection').modal('show');
  });

  // Remove this sub-collection button clicked
  $('#collection-controls').find('.remove-sub-collection-button').on('click', function (e) {
    e.preventDefault();
    $('#collection-remove-sub-collection').modal('show');
  });

});
