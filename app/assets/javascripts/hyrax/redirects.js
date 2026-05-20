// Behavior for the Aliases form (see app/views/hyrax/base/_form_redirects.html.erb).
// Event-delegated handlers on document so dynamically-added rows work
// without rebinding. A sentinel on document guards against the IIFE
// running twice (Turbolinks evaluates module scripts again on some
// navigation paths in development), which would otherwise stack
// duplicate listeners and fire each handler N times per click.
(function() {
    if (document.hyraxRedirectsBound) return;
    document.hyraxRedirectsBound = true;

    document.addEventListener('input', function(event) {
        var pathInput = event.target.closest('[data-redirects-path-input]');
        if (!pathInput) return;
        var radioId = pathInput.getAttribute('data-redirects-display-radio');
        var radio = document.getElementById(radioId);
        if (radio) radio.disabled = (pathInput.value.trim() === '');
    });

    document.addEventListener('click', function(event) {
        var removeButton = event.target.closest('[data-redirects-remove-row]');
        if (removeButton) {
            var row = removeButton.closest('tr');
            if (row) row.parentNode.removeChild(row);
            return;
        }

        var addButton = event.target.closest('[data-redirects-add-row]');
        if (!addButton) return;
        var template = document.querySelector('[data-redirects-row-template]');
        var table = document.querySelector('[data-redirects-table]');
        if (!template || !table) return;
        var tbody = table.querySelector('tbody');
        if (!tbody) return;
        // Monotonic counter on the table; never recycle an index after a
        // row is removed. Fallback to row count when the attribute is
        // missing (older adopter override of the partial).
        var nextIndex = parseInt(table.dataset.nextIndex, 10);
        if (isNaN(nextIndex)) {
            nextIndex = tbody.querySelectorAll('[data-redirects-row]').length;
        }
        var html = template.innerHTML.replace(/__INDEX__/g, nextIndex);
        tbody.insertAdjacentHTML('beforeend', html);
        table.dataset.nextIndex = String(nextIndex + 1);
    });
})();
