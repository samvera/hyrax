Blacklight.onLoad(function() {
  $('#monthly-btn').click(function() {
    var summaryButton = $('#summary-btn')
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-default');
    summaryButton.removeClass('btn-primary');
    summaryButton.addClass('btn-default');
  });

  $('#summary-btn').click(function() {
    var monthlyButton = $('#monthly-btn')
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-default');
    monthlyButton.removeClass('btn-primary');
    monthlyButton.addClass('btn-default');
  });
});
