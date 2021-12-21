Blacklight.onLoad(function() {
  var summaryButton = $('#summary-btn');
  var monthlyButton = $('#monthly-btn');
  var rangeButton = $('#range-btn');

  $('#monthly-btn').on('click', function() {
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-secondary');
    summaryButton.removeClass('btn-primary');
    summaryButton.addClass('btn-secondary');
    rangeButton.removeClass('btn-primary');
    rangeButton.addClass('btn-secondary');
  });

  $('#summary-btn').on('click', function() {
    
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-secondary');
    monthlyButton.removeClass('btn-primary');
    monthlyButton.addClass('btn-secondary');
    rangeButton.removeClass('btn-primary');
    rangeButton.addClass('btn-secondary');
  });

  $('#range-btn').on('click', function() {
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-secondary');
    monthlyButton.removeClass('btn-primary');
    monthlyButton.addClass('btn-secondary');
    summaryButton.removeClass('btn-primary');
    summaryButton.addClass('btn-secondary');
  });
});
