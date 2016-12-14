Blacklight.onLoad(function() {
  function toggle_icon(itag){
	 itag.toggleClass("caret");
	 itag.toggleClass("caret up");
  }

  $(".sorts-dash").click(function(){
    var itag =$(this).find('i');
    toggle_icon(itag);
    sort = itag.attr('class') == "caret" ? itag.attr('id') + ' desc' : itag.attr('id') + ' asc';
    $('#sort').val(sort).selected = true;
    $("#dashboard_sort_submit").click();
  });

  $(".sorts").click(function(){
    var itag =$(this).find('i');
    toggle_icon(itag);
    sort = itag.attr('class') == "caret" ? itag.attr('id') + ' desc' :  itag.attr('id');
    // There is more than one input named sort on the page, so qualifiy with the form class:
    $('.form-search input[name="sort"]').attr('value', sort);
    $("#user_submit").click();
  });
}); //end of Blacklight.onload
