class TrackingTags {
  constructor(provider) {
    this.provider = provider
  }

  analytics() {
    switch(this.provider) {
    case "matomo":
      return _paq;
    case "ga4":
      return dataLayer;
    default:
      return _gaq;
    }
  }

  pageView() {
    switch(this.provider) {
    case "matomo":
      return 'trackPageView';
    case "ga4":
      return 'event';
    default:
      return '_trackPageview';
    }
  }

  trackEvent() {
    switch(this.provider) {
    case "matomo":
      return 'trackEvent';
    case "ga4":
      return 'event';
    default:
      return '_trackEvent';
    }
  }
}

function trackPageView(provider) {
  if(provider !== 'ga4'){
    window.trackingTags.analytics().push([window.trackingTags.pageView()]);
  }
}

function trackAnalyticsEvents(provider) {
  $('span.analytics-event').each(function(){
    var eventSpan = $(this)
    if(provider !== 'ga4') {
      window.trackingTags.analytics().push([window.trackingTags.trackEvent(), eventSpan.data('category'), eventSpan.data('action'), eventSpan.data('name')]);
    } else {
      gtag('event', eventSpan.data('action'), { 'content_type': eventSpan.data('category'), 'content_id': eventSpan.data('name')})
    }
  })
}

function setupTracking() {
    var provider = $('meta[name="analytics-provider"]').prop('content')
    if (provider === undefined) {
      return;
    }
    window.trackingTags = new TrackingTags(provider)
    trackPageView(provider)
    trackAnalyticsEvents(provider)
}

if (typeof Turbolinks !== 'undefined') {
  $(document).on('turbolinks:load', function() {
    setupTracking()
  })
} else {
  $(document).ready(function() {
    setupTracking()
  })
}

$(document).on('click', '#file_download', function(e) {
  var provider = $('meta[name="analytics-provider"]').prop('content')
  if (provider === undefined) {
    return;
  }
  window.trackingTags = new TrackingTags(provider)

  if(provider !== 'ga4') {
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set', 'file-set-download', $(this).data('label')]);
    window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set-in-work', 'file-set-in-work-download', $(this).data('work-id')]);
    $(this).data('collection-ids').forEach(function (collection) {
      window.trackingTags.analytics().push([trackingTags.trackEvent(), 'file-set-in-collection', 'file-set-in-collection-download', collection]);
      window.trackingTags.analytics().push([trackingTags.trackEvent(), 'work-in-collection', 'work-in-collection-download', collection]);
    });
  } else {
    gtag('event', 'file-set-download', { 'content_type': 'file-set', 'content_id': $(this).data('label')})
    gtag('event', 'file-set-in-work-download', { 'content_type': 'file-set-in-work', 'content_id': $(this).data('work-id')})
    $(this).data('collection-ids').forEach(function (collection) {
      gtag('event', 'file-set-in-collection-download', { 'content_type': 'file-set-in-collection', 'content_id': collection })
      gtag('event', 'work-in-collection-download', { 'content_type': 'work-in-collection', 'content_id': collection })
    });
  }
});
