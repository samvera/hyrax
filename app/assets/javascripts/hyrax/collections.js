Blacklight.onLoad(function () {

  // change the action based which collection is selected
  // This expects the form to have a path that includes the string 'collection_replace_id'
  $('[data-behavior="updates-collection"]').on('click', function() {
      var string_to_replace = "collection_replace_id"
      var form = $(this).closest("form");
      var collection_id = $(".collection-selector:checked")[0].value;
      form[0].action = form[0].action.replace(string_to_replace, collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');
  });

  // background banner image uploaded for branding  
  $(".banner[data-background]").each(function() {
    var $banner = $(this);
    var url = 'url(' + $banner.data('background') + ')';
    $banner.css({ "backgroundImage": url });
  })

  // Show add collection to collection modal window
  $('#documents').find('.add-to-collection').on('click', function(e) {
      e.preventDefault();
      var notNestable = $(this).data('nestable') === false;
      var hasAccess = $(this).data('hasaccess') === true;
      var collectionId = $(this).parents('tr')[0].id.split('_')[1];

      if (notNestable) {
        $('#add-to-collection-deny-modal').modal('show');
      } else if (hasAccess) {
        $('#add-to-collection-modal-' + collectionId).modal('show');
      } else {
        $('#add-to-collection-permission-deny-modal').modal('show');
      }
  });

  // Display access deny for edit request.
  $('#documents').find('.edit-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#collections-to-edit-deny-modal').modal('show');
  });

  // Delete collection button click from within a collection row
  $('#documents').find('.delete-collection-button').on('click', function (e) {
    e.preventDefault();

    var totalitems = $(this).data('totalitems');
    // membership set to true indicates admin_set
    var membership = $(this).data('membership') === true;
    var hasaccess = $(this).data('hasaccess') === true;    

    var collectionId = $(this).parents('tr')[0].id.split('_')[1];
    
    if (hasaccess === false) {
      $('#collection-to-delete-deny-modal').modal('show');
    } else if (totalitems > 0) {
      if (membership) {
         $('#collection-admin-set-delete-deny-modal-' + collectionId).modal('show');
      }
      else{
         $('#collection-to-delete-modal-' + collectionId).modal('show')
      }
    } else {
      if (membership) {
        $('#collection-admin-set-empty-to-delete-modal-' + collectionId).modal('show');
      }
      else {
        $('#collection-empty-to-delete-modal-' + collectionId).modal('show');
      }
    }
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
});
