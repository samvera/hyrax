Blacklight.onLoad(function () {

  /**
   * Sync collection data attributes to the singular instance of the modal so it knows what data to post
   * @param {string} modalId - The id of modal to target, ie. #add_collection_modal
   * @param {[string]} dataAttributes - An string array of "data-xyz" data attributes WITHOUT
   * the "data-" prefix. ie. ['id', 'some-var']
   * @param {jquery Object} $tr - jQuery object reference to a table row
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
    markup = options.join('');
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

  // change the action based which collection is selected
  // This expects the form to have a path that includes the string 'collection_replace_id'
  $('[data-behavior="updates-collection"]').on('click', function() {
      var string_to_replace = "collection_replace_id",
        form = $(this).closest("form"),
        collection_id = $(".collection-selector:checked")[0].value;

      form[0].action = form[0].action.replace(string_to_replace, collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');
  });


  // Set up click listeners for collections buttons which initiate modal action windows
  $('.add-to-collection').on('click', handleAddToCollection);
  $('.delete-collection-button').on('click', handleDeleteCollection);


  // Display access deny for edit request.
  $('#documents').find('.edit-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#collections-to-edit-deny-modal').modal('show');
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

    tableRows.each(function(i, row) {
      checkbox = $(row).find('td:first input[type=checkbox]');
      if (typeof checkbox[0] !== "undefined") {
        if (checkbox[0].checked) {
          numRowsSelected++;
        }
      }
    });

    if (numRowsSelected > 0) {
      // Collections are selected
      // Update singular / plural text in delete modal
      if (numRowsSelected > 1) {
        $deleteWordingTarget.text(deleteWording.plural);
      } else {
        $deleteWordingTarget.text(deleteWording.singular);
      }
      $('#selected-collections-delete-modal').modal('show');
    } else {
      // No collections are selected
      $('#collections-to-delete-deny-modal').modal('show');
    }
  });

  $('#show-more-parent-collections').on('click', function () {
    $(this).hide();
    $("#more-parent-collections").show();
    $("#show-less-parent-collections").show();
  });

  $('#show-less-parent-collections').on('click', function () {
    $(this).hide();
    $("#more-parent-collections").hide();
    $("#show-more-parent-collections").show();
  });
});
