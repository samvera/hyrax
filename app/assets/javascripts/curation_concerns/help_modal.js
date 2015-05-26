$(function(){
  var $window = $(window),
      $modal = $('#ajax-modal'),
      resolution = screen.width + 'x' + screen.height,
      viewport = $window.width() + 'x' + $window.height(),
      current_url = document.location.href;

  function populateHelpForm(){
    // Removing the "NOT" portion
    $('#help-js strong').remove();
    $('#help_request_javascript_enabled').val(1);

    $('#help-resolution').text(resolution);
    $('#help_request_resolution').val(resolution);

    $('#help-viewport').text(viewport);
    $('#help_request_view_port').val(viewport);

    $('#help-url').text(current_url);
    $('#help_request_current_url').val(current_url);
  }
  populateHelpForm();

  $('.request-help').on('click', function(event){
    event.preventDefault();

    $('body').modalmanager('loading');

    setTimeout(function(){
      $modal.load('/help_requests/new #new_help_request', function(){
        $modal.modal();
        populateHelpForm();
      });
    }, 1000);
  });
});
