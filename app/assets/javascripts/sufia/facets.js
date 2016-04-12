Blacklight.onLoad(function() {
  /*
   * facets lists
   */
  $("li.expandable").click(function(){
    $(this).next("ul").slideToggle();
    $(this).find('i').toggleClass("glyphicon-chevron-right glyphicon-chevron-down");
  });

  $("li.expandable_new").click(function(){
    $(this).find('i').toggleClass("glyphicon-chevron-right glyphicon-chevron-down");
  });

}); //end of Blacklight.onload
