//= require blacklight/core
(function($) {
  var facet_mine_behavior = function() {
    $('#aux-search-submit-header').hide();

    $('input[name="works"]').on("change", function(e) {
      $(this).closest('form').submit();
    });

  };  


  // TODO when we upgrade blacklight to 4.4+, we can use Blacklight.onLoad()
  if (typeof Turbolinks !== "undefined") {
    $(document).on('page:load', function() {
      facet_mine_behavior();  
    });
  }
  $(document).ready(function() {
    facet_mine_behavior();  
  });
})(jQuery);
