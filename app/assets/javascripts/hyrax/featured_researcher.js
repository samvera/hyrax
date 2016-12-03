
// The selector for the User field (external_key field) on the
// featured researcher form

(function( $ ){
  $.fn.userSelector = function( options ) {
    $(".select2-user").userSearch();
  };
})( jQuery );

Blacklight.onLoad(function() {
  $('.select2-user').userSelector();
});

