//= require jquery.tagcloud
//= require jquery.tinysort.min

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
      var $tagCloud = $(this)
      $.ajax({url:"/catalog/facet/"+facet_name+".json"}).done(function(data) {
        data.response.facets.items.map(function(item) {
          $tagCloud.append('<li rel="'+item.hits+'" title="'+item.value+'"><a href="/catalog?f['+facet_name+'][]='+item.value+'">'+item.value+'&emsp;</a><span class="badge facet-count">'+item.hits+'</span></li>');
        });
        $tagCloud.tagcloud(options);
        $tagCloud.children().tsort({attr:'title', order:'asc'});
      });
      $tagCloud.siblings('.tag-toggle-list').each(function() { 
        var $toggle = $(this)
        $toggle.click(function() { 
          $tagCloud.toggleClass("list"); 
          $toggle.text( $toggle.text()=="Cloud"?"List":"Cloud");
        });
      });
      $tagCloud.siblings('.tag-sort').children().each(function() {
        var $btn = $(this)
        if ($btn.hasClass('tag-sort-az')) { var opts = {attr:'title', order:'asc'} }
        else if ($btn.hasClass('tag-sort-za')) { var opts = {attr:'title', order:'desc'} }
        else if ($btn.hasClass('tag-sort-numerical')) { var opts = {attr:'rel', order:'desc'} }
        if (opts) {
          $btn.click(function() { $tagCloud.children().tsort(opts); });
        }; 
      });
    });

  };
})( jQuery );