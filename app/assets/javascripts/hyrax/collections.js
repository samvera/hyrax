Blacklight.onLoad(function () {

  /**
   * Post modal data via Ajax to avoid nesting <forms> in edit collections tabs screen
   * @param  {string} url   URL where to submit the AJAX request
   * @param  {string} type  The type of network request: 'POST', 'DELETE', etc.
   * @param  {object} data  Data object to send with network request.  Should default to {}
   * @param  {jQuery object} $self Reference to the jQuery context ie. $(this) of calling statemnt
   * @return {void}
   */
  function submitModalAjax(url, type, data, $self) {
    $.ajax({
      type: type,
      url: url,
      data: data
    }).done(function(response) {
    }).fail(function(err) {
      var alertNode = buildModalErrorAlert(err);
      var $alert = $self.closest('.modal').find('.modal-ajax-alert');
      $alert.html(alertNode);
    });
  }

  /**
   * HTML for ajax error alert message, in case the AJAX request fails
   * @param  {object} err AJAX response object
   * @return {string}     The constructed HTML alert string
   */
  function buildModalErrorAlert(err) {
    var message = (err.responseText ? err.responseText : 'An unknown error has occurred');
    var elHtml = '<div class="alert alert-danger alert-dismissible" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><span class="message">' + message + '</span></div>';
    return elHtml;
  }

  /**
   * Handle delete collection submit button click from within a generic modal
   * @return {void}
   */
  function handleModalDeleteCollection() {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postDeleteUrl'),
      data = {};
    if (url.length === 0) {
      return;
    }
    $self.prop('disabled', true);
    submitModalAjax(url, 'DELETE', data, $self);
  }

  /**
   * Sync collection data attributes to the singular instance of the modal so it knows what data to post
   * @param {string} modalId - The id of modal to target, ie. #add_collection_modal
   * @param {[string]} dataAttributes - An string array of "data-xyz" data attributes WITHOUT
   * the "data-" prefix. ie. ['id', 'some-var']
   * @param {jquery Object} $dataEl - jQuery object reference which has values of data attributes we're copying over
   * @return {void}
   */
  function addDataAttributesToModal(modalId, dataAttributes, $dataEl) {
    // Remove and add new data attributes
    dataAttributes.forEach(function(attribute) {
      $(modalId).removeAttr('data-' + attribute).attr('data-' + attribute, $dataEl.data(attribute));
    });
  }

  /**
   * Build <option>s markup for add collection to collection
   * @param  {[objects]} collsHash An array of objects representing a needed data from Collection(s)
   * @return {string} <options> string markup which will populate the <select> element
   */
  function buildSelectMarkup(collsHash) {
    var options = collsHash.map(function(col) {
      return '<option value="' + col.id + '">' + col.title_first + '</option>';
    });
    var markup = options.join('');
    return markup;
  }

  /**
   * Handle "add to collection" element click event.
   * @param  {Mouseevent} e
   * @return {void}
   */
  function handleAddToCollection(e) {
    e.preventDefault();
    var $self = $(this),
      $dataEl = (
        $self.closest('#collections-list-table').length > 0 ?
        $self.closest('tr') :
        $self.closest('section')
      ),
      selectMarkup = '',
      $firstOption = null;

    // Show deny modal
    if ($self.data('nestable') === false) {
      $('#add-to-collection-deny-modal').modal('show');
      return;
    }
    // Show modal permission denied
    if ($self.data('hasaccess') === false) {
      $('#add-to-collection-permission-deny-modal').modal('show');
      return;
    }
    // Show add to collection modal below
    addDataAttributesToModal('#add-to-collection-modal', ['id', 'post-url'], $dataEl);
    // Grab reference to the default <option> in modal
    $firstOption = $('#add-to-collection-modal').find('select[name="parent_id"] option');
    // Remove all previous <options>s
    $firstOption.not(':first').remove();
    // Build new <option>s markup and put on DOM
    selectMarkup = buildSelectMarkup($dataEl.data('collsHash'));
    $(selectMarkup).insertAfter($firstOption);

    // Disable the submit button in modal by default
    $('#add-to-collection-modal').find('.modal-submit-button').prop('disabled', true);

    // Show modal
    $('#add-to-collection-modal').modal('show');
  }

  /**
   * Handle "delete collection" button click event
   * @param  {Mouseevent} e
   * @return {void}
   */
  function handleDeleteCollection(e) {
    e.preventDefault();
    var $self = $(this),
      $tr = $self.parents('tr'),
      totalitems = $self.data('totalitems'),
      // membership set to true indicates admin_set
      membership = $self.data('membership') === true,
      collectionId = $tr.data('id'),
      modalId = '';

    // Permissions denial
    if ($(this).data('hasaccess') !== true) {
      $('#collection-to-delete-deny-modal').modal('show');
      return;
    }
    // Admin set with child items
    if (totalitems > 0 && membership) {
      $('#collection-admin-set-delete-deny-modal').modal('show');
      return;
    }
    modalId = (totalitems > 0 ?
      '#collection-to-delete-modal' :
      '#collection-empty-to-delete-modal'
    );
    addDataAttributesToModal(modalId, ['id', 'post-delete-url'], $tr);
    $(modalId).modal('show');
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
  });

  // Add click listeners for collections buttons which initiate modal action windows
  $('.add-to-collection').on('click', handleAddToCollection);
  $('.delete-collection-button').on('click', handleDeleteCollection);

  // change the action based which collection is selected
  // This expects the form to have a path that includes the string 'collection_replace_id'
  $('[data-behavior="updates-collection"]').on('click', function() {
      var string_to_replace = "collection_replace_id",
        form = $(this).closest("form"),
        collection_id = $(".collection-selector:checked")[0].value;

      form[0].action = form[0].action.replace(string_to_replace, collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');
  });

  // Display access deny for edit request.
  $('#documents').find('.edit-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#collections-to-edit-deny-modal').modal('show');
  });

  // Display access deny for remove parent collection button.
  $('#parent-collections-wrapper').find('.remove-parent-from-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#parent-collection-to-remove-deny-modal').modal('show');
  });

  // Remove this parent collection list button clicked
  $('#parent-collections-wrapper')
    .find('.remove-from-collection-button')
    .on('click', function (e) {
    var $dataEl = $(this).closest('li'),
      modalId = '#collection-remove-from-collection-modal';

    addDataAttributesToModal(modalId, ['id', 'parent-id', 'post-url'], $dataEl);
    $(modalId).modal('show');
  });

  // Remove this sub-collection list button clicked
  $('#sub-collections-wrapper')
    .find('.remove-subcollection-button')
    .on('click', function (e) {
    var $dataEl = $(this).closest('li'),
      modalId = '#collection-remove-subcollection-modal';

    addDataAttributesToModal(modalId, ['id', 'parent-id', 'post-url'], $dataEl);
    $(modalId).modal('show');
  });

  // Remove collection from list modal "Submit/Remove" button clicked
  $('.modal-button-remove-collection').on('click', function(e) {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postUrl'),
      data = {};
    if (url.length === 0) {
      return;
    }
    $self.prop('disabled', true);
    submitModalAjax(url, 'POST', data, $self);
  });

  // Delete selected collections button click
  $('#delete-collections-button').on('click', function () {
    var tableRows = $('#documents table.collections-list-table tbody tr');
    var checkbox = null;
    var numRowsSelected = false;
    var deleteWording = {
      plural: 'these collections',
      singular: 'this collection'
    };
    var $deleteWordingTarget = $('#selected-collections-delete-modal .pluralized');

    var canDeleteAll = true;
    var selectedInputs = $('#documents table.collections-list-table tbody tr')
      // Get all inputs in the table
      .find('td:first input[type=checkbox]')
      // Filter to those that are checked
      .filter(function(i, checkbox) { return checkbox.checked; });

    var cannotDeleteInputs = selectedInputs.filter(function(i, checkbox) { return checkbox.dataset.hasaccess === "false"; });
    if(cannotDeleteInputs.length > 0) {
      // TODO: Can we pass data to this modal to be more specific about which ones they cannot delete?
      $('#collections-to-delete-deny-modal').modal('show');
      return;
    }

    if (selectedInputs.length > 0) {
      // Collections are selected
      // Update singular / plural text in delete modal
      if (selectedInputs.length > 1) {
        $deleteWordingTarget.text(deleteWording.plural);
      } else {
        $deleteWordingTarget.text(deleteWording.singular);
      }
      $('#selected-collections-delete-modal').modal('show');
    }
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
    $(id).find('.modal-delete-button').on('click', handleModalDeleteCollection);
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
