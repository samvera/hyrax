Blacklight.onLoad(function () {

  // Post modal data via Ajax to avoid nesting <forms> in edit collections tabs screen
  function submitModalAjax(url, data, $self) {
    $.ajax({
      type: 'POST',
      url: url,
      data: data
    }).done(function(response) {
      console.log('response', response);
    }).fail(function(err) {
      var alertNode = buildModalErrorAlert(err);
      var $alert = $self.closest('.modal').find('.modal-ajax-alert');
      $alert.html(alertNode);
    });
  }

  // HTML for ajax error alert message, in case the AJAX request fails
  function buildModalErrorAlert(err) {
    var message = (err.responseText ? err.responseText : 'An unknown error has occurred');
    var el = '<div class="alert alert-danger alert-dismissible" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><span class="message">' + message + '</span></div>';
    return el;
  }

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

  // Add to collection modal form post
  $('[id^="add-to-collection-modal-"]').find('.modal-add-button').on('click', function (e) {
    var url = $(this).data('postUrl'),
      parentId = $(this).closest('.modal').find('[name="parent_id"]').val(),
      $self = $(this),
      data = {
      parent_id: parentId,
      source: $(this).data('source')
    };
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, data, $self);
  });

  // Add sub collection to collection form post
  $('[id^="add-subcollection-modal-"]').find('.modal-add-button').on('click', function (e) {
    var url = $(this).data('postUrl'),
      childId = $(this).closest('.modal').find('[name="child_id"]').val(),
      data = {
      child_id: childId,
      source: $(this).data('source')
    };
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, data);
  });

  // Handle add a subcollection button click on the collections show page
  $('.sub-collections-wrapper button.add-subcollection').on('click', function (e) {
    $('#add-subcollection-modal-' + $(this).data('presenterId')).modal('show');
  });
});
