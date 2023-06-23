class TrackingTags {
  constructor(provider) {
    this.provider = provider
    switch(this.provider) {
    case 'matomo':
      this.tracker = new MatomoTagTracker();
      break;
    case 'google':
      this.tracker = new UATagTracker();
      break;
    case 'ga4':
      this.tracker = new GA4TagTracker();
      break;
    default:
      console.error('Unsupport analytics provider ' + this.provider + ', supported values are: matomo, google, ga4');
    }
  }

  // Track an event with the configured provider
  trackTagEvent(category, action, name) {
    this.tracker.trackEvent(category, action, name);
  }

  // Track a page view with the configured provider
  trackPageView() {
    this.tracker.trackPageView();
  }

  // Deprecated: use trackTagEvent and trackPageView instead.
  analytics() {
    return this;
  }

  // Deprecated: use trackTagEvent and trackPageView instead.
  push(params) {
    if (params[0] == 'trackPageView' || params[0] == '_trackPageView') {
      this.tracker.trackPageView();
    } else {
      this.tracker.trackTagEvent(params[1], params[2], params[3]);
    }
  }

  // Deprecated
  pageView() {
    return 'trackPageView';
  }

  // Deprecated
  trackEvent() {
    return 'trackEvent';
  }
}

class GA4TagTracker {
  trackEvent(category, action, name) {
    gtag('event', action, {
      'category': category,
      'label': name
    });
  }

  trackPageView() {
    // No operation necessary, this event is automatically collected
  }
}

class UATagTracker {
  trackEvent(category, action, name) {
    _gaq.push(['_trackEvent', category, action, name]);
  }

  trackPageView() {
    _gaq.push(['_trackPageView']);
  }
}

class MatomoTagTracker {
  trackEvent(category, action, name) {
    _paq.push(['trackEvent', category, action, name]);
  }

  trackPageView() {
    _paq.push(['trackPageView']);
  }
}

function trackPageView() {
  window.trackingTags.trackPageView();
}

function trackAnalyticsEvents() {
  $('span.analytics-event').each(function(){
    var eventSpan = $(this);
    window.trackingTags.trackTagEvent(eventSpan.data('category'), eventSpan.data('action'), eventSpan.data('name'));
  })
}

function setupTracking() {
  var provider = $('meta[name="analytics-provider"]').prop('content')
  if (provider === undefined) {
    return;
  }
  window.trackingTags = new TrackingTags(provider);
  trackPageView();
  trackAnalyticsEvents();
}

if (typeof Turbolinks !== 'undefined') {
  $(document).on('turbolinks:load', function() {
    setupTracking();
  });
} else {
  $(document).on('ready', function() {
    setupTracking();
  });
}

$(document).on('click', '#file_download', function(e) {
  window.trackingTags.trackTagEvent('file-set', 'file-set-download', $(this).data('label'));
  window.trackingTags.trackTagEvent('file-set-in-work', 'file-set-in-work-download', $(this).data('work-id'));
  $(this).data('collection-ids').forEach(function (collection) {
    window.trackingTags.trackTagEvent('file-set-in-collection', 'file-set-in-collection-download', collection);
    window.trackingTags.trackTagEvent('work-in-collection', 'work-in-collection-download', collection);
  });
});
