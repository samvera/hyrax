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
