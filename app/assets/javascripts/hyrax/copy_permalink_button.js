// Wires the "Copy permalink" button (on work and collection show pages) to
// ClipboardJS. The button ships with the button label as its `title` so a
// pre-init hover shows something sensible; we initialize a manual-trigger
// Bootstrap tooltip so the browser's native title-attribute tooltip stops
// appearing on hover. On a successful copy we swap the tooltip text to the
// "Copied!" message, show it briefly, then restore the original label.
Blacklight.onLoad(function () {
  var $buttons = $('.copy-permalink-button');
  if (!$buttons.length) { return; }

  $buttons.tooltip({ trigger: 'manual' });

  var clipboard = new Clipboard('.copy-permalink-button');

  clipboard.on('success', function (e) {
    var $btn = $(e.trigger);
    var originalLabel = $btn.attr('data-original-title');
    var successText = $btn.attr('data-success-text');

    $btn.attr('data-original-title', successText).tooltip('show');

    setTimeout(function () {
      $btn.tooltip('hide').attr('data-original-title', originalLabel);
    }, 1500);

    e.clearSelection();
  });
});
