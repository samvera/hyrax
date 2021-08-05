// Callbacks for tracking events using Google Analytics
$(document).on('click', '#file_download', function(e) {
  _gaq.push(['_trackEvent', 'Files', 'Downloaded', $(this).data('label')]);    
});