Blacklight.onLoad(function () {

  // Post modal data via Ajax to avoid nesting <forms> in edit collections tabs screen
  function submitModalAjax(url, type, data, $self) {
    $.ajax({
      type: type,
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

  function handleDeleteCollection() {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postDeleteUrl'),
      data = {};
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, 'DELETE', data, $self);
  }

  /**
   * Generically disable modal submit buttons unless their select element
   * has a valid value.
   *
   * To Use:
   * 1.) Put the '.disable-unless-selected' class on the '.modal' element you wish to protect.
   * 2.) Add the 'disabled' attribute to your protected submit button ie. <button disabled ...>.
   * 3.) Put the '.modal-submit-button' class on whichever button you wish to disable for an invalid
   * <select> value ie. <button disabled class="... modal-submit-button" ...>
   *
   * @return {void}
   */
  $('.modal.disable-unless-selected select').on('change', function() {
    var selectValue = $(this).val(),
      emptyValues = ['', 'none'],
      selectHasAValue = emptyValues.indexOf(selectValue) === -1,
      $submitButton = $(this).parents('.modal').find('.modal-submit-button');

    $submitButton.prop('disabled', !selectHasAValue);
  })

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
  $('#add-to-collection-modal').find('.modal-add-button').on('click', function (e) {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postUrl'),
      parentId = $modal.find('[name="parent_id"]').val(),
      data = {
        parent_id: parentId,
        source: $self.data('source')
      };
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, 'POST', data, $self);
  });

  // Handle delete collection modal submit button click event
  ['#collection-to-delete-modal', '#collection-empty-to-delete-modal'].forEach(function(id) {
    $(id).find('.modal-delete-button').on('click', handleDeleteCollection);
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
    submitModalAjax(url, 'POST', data, $(this));
  });

  // Handle add a subcollection button click on the collections show page
  $('.sub-collections-wrapper button.add-subcollection').on('click', function (e) {
    $('#add-subcollection-modal-' + $(this).data('presenterId')).modal('show');
  });
});
