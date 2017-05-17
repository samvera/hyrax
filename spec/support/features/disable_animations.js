// disable_animations.js
// Disables any CSS or Javascript-based animation such as collapsed menu items
// or nodes. This avoides timing errors in Poltergeist, which much wait for these
// amimations to complete before interacting with the page.

window.onload = function() {
    // opens all the collapsed divs in the batch edit form
    $('div.scrolly').addClass('collapse');
    $('div.scrolly').addClass('in');
}
