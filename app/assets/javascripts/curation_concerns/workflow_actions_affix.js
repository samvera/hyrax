Blacklight.ready(function() {
  $(document).on('scroll', function() {
    var workflowDiv = $('#workflow_controls');
    if($(window).scrollTop() + $(window).height() == $(document).height()){
      workflowDiv.removeClass('workflow-affix');
    } 
    if($(window).scrollTop() + $(window).height() < $('.form-actions').position().top) {
      workflowDiv.addClass('workflow-affix');
    }
  });
});
