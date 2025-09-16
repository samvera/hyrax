(function($) {
  $.fn.collectionSearch = function() {
    return this.each(function() {
      var $select = $(this);

      // Skip if already initialized
      if ($select.hasClass('select2-hidden-accessible') && $select.data('select2')) {
        return;
      }

      $select.select2({
        placeholder: $select.data('placeholder') || 'Select',
        allowClear: true,
        dropdownParent: $select.closest('.modal-body')
      });
    });
  };
})(jQuery);

Blacklight.onLoad(function() {
  $('select.collection-select2').collectionSearch();
});

// Fix for if select2 breaks because of clicking the back button on the browser
// Essentially we delete the leftover elements and reinitialize it
window.addEventListener('popstate', function(event) {
  Blacklight.onLoad(function() {
    $('.select2-drop-mask').remove();
    $('.select2-drop').remove();

    $('select.collection-select2').each(function() {
      var $select = $(this);

      // Find and remove the broken Select2 container
      $select.siblings('.select2-container').remove();
      $select.next('.select2-container').remove();
      $select.parent().find('.select2-container').remove();

      // Make sure the select is visible and ready
      $select.show().removeClass('select2-hidden-accessible');

      $select.collectionSearch();
    });
  });
});
