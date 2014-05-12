// Callbacks for tracking events using Google Analytics

// Note: there is absence of testing here.  I'm not sure how or to what extent we can test what's getting
// sent to Google Analytics.

$(document).on('click', '#file_download', function(e) {
  _gaq.push(['_trackEvent', 'Files', 'Downloaded', $(this).data('label')]);
    
});

