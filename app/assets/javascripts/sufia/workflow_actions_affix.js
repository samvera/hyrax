Blacklight.onLoad(function() {
  if ($('.workflow-actions').length) {
    $(document).on('scroll', function() {
      var workflowDiv = $('#workflow_controls');
      var workflowDivPos = $('.workflow-actions').offset().top + $('#workflow_controls').height();
      workflowDiv.removeClass('workflow-affix');
      if(workflowDivPos > ($(window).scrollTop() + $(window).height())){
        workflowDiv.addClass('workflow-affix');
      } else {
        workflowDiv.removeClass('workflow-affix');
      }
    });
  }
});
