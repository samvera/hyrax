//= require blacklight/core
(function($) {
  var facet_mine_behavior = function() {
    // TODO: pull in https://github.com/projecthydra-labs/curate/blob/master/app/views/catalog/_facets.html.erb
    $('#aux-search-submit-header').hide();

    $('input[name="works"]').on("change", function(e) {
      $(this).closest('form').submit();
    });

  };

  Blacklight.onLoad(function() {
    facet_mine_behavior();
  });
})(jQuery);
