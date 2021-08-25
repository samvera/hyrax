class TrackingTags {
  constructor(provider) {
    this.provider = provider
  }

  analytics() {
    if(this.provider == "matomo") {
      return _paq;
    }
    else {
      return _gaq
    }
  }

  pageView() {
    if(this.provider == "matomo") {
      return 'trackPageView'
    } else {
      return '_trackPageview'
    }
  }

  trackEvent() {
    if(this.provider == "matomo") {
      return 'trackEvent'
    } else {
      return '_trackEvent'
    }
  }
}

function trackPageView() {
  window.trackingTags.analytics().push([window.trackingTags.pageView()]);
}

function trackAnalyticsEvents() {
  $('span.analytics-event').each(function(){
    var eventSpan = $(this)
    window.trackingTags.analytics().push([window.trackingTags.trackEvent(), eventSpan.data('category'), eventSpan.data('action'), eventSpan.data('name')]);
  })
}

function setupTracking() {
    var provider = $('meta[name="analytics-provider"]').prop('content')
    window.trackingTags = new TrackingTags(provider)
    trackPageView()
    trackAnalyticsEvents()
}

if (typeof Turbolinks !== 'undefined') {
  $(document).on('turbolinks:load', function() {
    setupTracking()
  })
} else {
  $(document).on('ready', function() {
    setupTracking()
  })
}

$(document).on('click', '#file_download', function(e) {
  var provider = $('meta[name="analytics-provider"]').prop('content')
  window.trackingTags = new TrackingTags(provider)
  window.trackingTags.analytics().push([trackingTags.trackEvent(), 'Files', 'Downloaded', $(this).data('label')]);
  window.trackingTags.analytics().push([trackingTags.trackEvent(), 'Works', 'Downloads', $(this).data('work-id')]);
  $(this).data('collection-ids').forEach(function (collection) {
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'Collections', 'Downloads', collection]);
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'Work in Collection', 'Downloads', collection]);
  });
});