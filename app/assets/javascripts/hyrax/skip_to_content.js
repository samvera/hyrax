// This code is to implement skip_to_content

Blacklight.onLoad(function () {
  $(".skip-to-content").on('click', function(event) {
    event.preventDefault();
    // element to focus on
    var skipTo = '#' + $(this)[0].firstElementChild.hash.split('#')[1];

    // Setting 'tabindex' to -1 takes an element out of normal
    // tab flow but allows it to be focused via javascript
    $(skipTo).attr('tabindex', -1).on('blur focusout', function () {
      $(this).removeAttr('tabindex');
    }).focus();
  });
});
