jQuery.fn.exists = function(){return this.length>0;}

Blacklight.onLoad(function () {
  // all activate-submit buttons are disabled by default
  $('.activate-submit').each(function() {
    $(this).prop('disabled', true);
  });
  // set up tooltip
  $('.activate-container').tooltip({
    'placement': 'bottom',
    'delay': {show: 500, hide: 100}
    });

  // when data-activate checkbox is clicked, change the
  // disable state of all activate-submit buttons
  $('input[data-activate]').on("click", function () {
    // get the checked state of the checkbox clicked and 
    // set  all other tos checkboxes to same state
    var bool = $(this).is(":checked");
    // if box is checked - enable submit, otherwise disable 
    var disable = (bool) ? false : true;
    $('input[data-activate]').attr('checked', bool);
    $('.activate-submit').attr('disabled', disable).attr('aria-disabled', disable);
  })

  // show/hide the tooltip depending if the agreement is already checked
  $('.activate-container').mousemove(function(e){
    if ($('input[data-activate]').is(':checked')) {
      $('.activate-container').tooltip('hide')
    }
    else {
      $('.activate-container').tooltip('show')
    }
  });
  $('.activate-container').mouseout(function(e){
      $('.activate-container').tooltip('hide')
  });
  $('.activate-container').mouseleave(function(e){
      $('.activate-container').tooltip('hide')
  });
});
