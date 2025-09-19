// Initialize collection-select2 dropdowns in a targeted way
// This runs after document ready to avoid interfering with other Select2 initializations

$(document).on('turbolinks:load', function() {
  // Use a longer delay to ensure controlled vocabulary Select2s are initialized first
  setTimeout(initializeCollectionSelect2, 500);
});

// Also handle regular page loads (non-turbolinks)
$(document).ready(function() {
  if (typeof Turbolinks === 'undefined') {
    setTimeout(initializeCollectionSelect2, 500);
  }
});

// Initialize on modal show events
$(document).on('shown.bs.modal', '.modal', function() {
  initializeCollectionSelect2();
});

function initializeCollectionSelect2() {
  // Only initialize collection-select2 elements that:
  // 1. Are not already initialized
  // 2. Are visible
  // 3. Are specifically for collection selection (not location fields)
  $('.collection-select2:visible:not(.select2-hidden-accessible)').each(function() {
    var $select = $(this);

    // Skip if this is inside a controlled vocabulary field (location search)
    if ($select.closest('.controlled_vocabulary').length > 0) {
      return;
    }

    var dropdownParent = $select.closest('.modal-body');
    var options = {
      placeholder: $select.data('placeholder') || 'Select',
      allowClear: true
    };

    if (dropdownParent.length > 0) {
      options.dropdownParent = dropdownParent;
    }

    $select.select2(options);
  });

  // Also initialize member_of_collection_ids selects that don't have collection-select2 class
  $('select[name="member_of_collection_ids"]:visible:not(.select2-hidden-accessible)').each(function() {
    var $select = $(this);

    // Skip if already has select2 or is inside controlled vocabulary
    if ($select.data('select2') || $select.closest('.controlled_vocabulary').length > 0) {
      return;
    }

    var dropdownParent = $select.closest('.modal-body');
    var options = {
      placeholder: $select.data('placeholder') || 'Select',
      allowClear: true
    };

    if (dropdownParent.length > 0) {
      options.dropdownParent = dropdownParent;
    }

    $select.select2(options);
  });
}