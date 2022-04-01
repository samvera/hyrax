Blacklight.onLoad(function() {
  /*
   * facets lists
   */
  $("li.expandable").on("click", function() {
    $(this).next("ul").slideToggle();
    $(this).find('i').toggleClass("fa-chevron-right fa-chevron-down");
  });

  $("li.expandable_new").on("click", function() {
    $(this).find('i').toggleClass("fa-chevron-right fa-chevron-down");
  });

}); //end of Blacklight.onload
