//= require jquery.tagcloud

(function( $ ){

  // Loads facet values for the facet specified in data-facet attribute
  // Displays the results as a tag cloud 
  // Passes all options through to the tagcloud jquery plugin.  See https://github.com/addywaddy/jquery.tagcloud.js for options.
  $.fn.blacklightTagCloud = function( options ) {  
    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    var $container = this;

    return this.each(function() {  
      var facet_name = $(this).data("facet");
      var $element = $(this)
      $.ajax({url:"/catalog/facet/"+facet_name+".json"}).done(function(data) {
        data.response.facets.items.map(function(item) {
          $element.append('<li rel="'+item.hits+'" title="'+item.value+'"><a href="/?f['+facet_name+'][]='+item.value+'">'+item.value+'</a><span class="facet-count">('+item.hits+')</span></li>');
        });
        $element.tagcloud(options);
      });
    });

  };
})( jQuery );