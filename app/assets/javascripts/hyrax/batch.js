Blacklight.onLoad(function() {
  $('#show_addl_descriptions').on('click', function() {
    $('#more_descriptions').show();
    $('#show_addl_descriptions').hide();
    return false;
  });
  $('#hide_addl_descriptions').on('click', function() {
    $('#more_descriptions').hide();
    $('#show_addl_descriptions').show();
    return false;
  });
  $('#more_descriptions').hide();
});