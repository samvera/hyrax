$(document).ready(function() {
  $(document).on('scroll', function() {
    var advisorDiv = $('#advisor_controls');
    if($(window).scrollTop() + $(window).height() == $(document).height()){
      $('#advisor_controls').removeClass('advisor_affix');
    } 
    if($(window).scrollTop() + $(window).height() < $('.form-actions').position().top) {
      $('#advisor_controls').addClass('advisor_affix');
    }
  });
});
