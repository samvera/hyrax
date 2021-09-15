Blacklight.onLoad(function() {
  var summaryButton = $('#summary-btn');
  var monthlyButton = $('#monthly-btn');
  var rangeButton = $('#range-btn');

  $('#monthly-btn').click(function() {  
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-default');
    summaryButton.removeClass('btn-primary');
    summaryButton.addClass('btn-default');
    rangeButton.removeClass('btn-primary');
    rangeButton.addClass('btn-default');
  });

  $('#summary-btn').click(function() {
    
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-default');
    monthlyButton.removeClass('btn-primary');
    monthlyButton.addClass('btn-default');
    rangeButton.removeClass('btn-primary');
    rangeButton.addClass('btn-default');
  });

  $('#range-btn').click(function() {
    $(this).addClass('btn-primary');
    $(this).removeClass('btn-default');
    monthlyButton.removeClass('btn-primary');
    monthlyButton.addClass('btn-default');
    summaryButton.removeClass('btn-primary');
    summaryButton.addClass('btn-default');
  });
});
