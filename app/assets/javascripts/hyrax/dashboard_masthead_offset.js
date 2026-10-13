// The dashboard's fixed-top nav is outside normal flow, so body needs
// padding-top to keep content from hiding behind it. A static CSS value
// (see body.dashboard in dashboard.scss) can't adapt to variable nav heights
// (tall logos, mobile collapse), so we measure the actual masthead and update
// whenever it resizes. On mobile the collapse is positioned absolutely below
// the nav (see _header.scss), so we add its height separately.
Blacklight.onLoad(function() {
  if (!document.body.classList.contains('dashboard')) return;

  var masthead = document.getElementById('masthead');
  if (!masthead) return;
  var collapse = document.getElementById('top-navbar-collapse');
  var observer;

  var update = function() {
    var h = masthead.offsetHeight;
    if (collapse && window.innerWidth < 992) h += collapse.offsetHeight;
    document.body.style.paddingTop = h + 'px';
  };

  update();
  window.addEventListener('resize', update);
  if (typeof ResizeObserver !== 'undefined') {
    observer = new ResizeObserver(update);
    observer.observe(masthead);
    if (collapse) observer.observe(collapse);
  } else {
    window.addEventListener('load', update);
    if (collapse) {
      // Bootstrap 4 fires via jQuery; Bootstrap 5 fires native events
      if (typeof jQuery !== 'undefined') jQuery(collapse).on('shown.bs.collapse hidden.bs.collapse', update);
      collapse.addEventListener('shown.bs.collapse', update);
      collapse.addEventListener('hidden.bs.collapse', update);
    }
  }

  document.addEventListener('turbolinks:before-cache', function() {
    window.removeEventListener('resize', update);
    window.removeEventListener('load', update);
    if (observer) observer.disconnect();
  }, { once: true });
});
