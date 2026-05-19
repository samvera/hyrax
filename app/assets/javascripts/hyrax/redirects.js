// Behavior for the Aliases form (see app/views/hyrax/base/_form_redirects.html.erb).
// Event-delegated handlers on document so dynamically-added rows work
// without rebinding. Registered once at script load — re-binding inside
// Blacklight.onLoad would stack a new listener on every Turbolinks visit.
(function() {
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
        var nextIndex = tbody.querySelectorAll('[data-redirects-row]').length;
        var html = template.innerHTML.replace(/__INDEX__/g, nextIndex);
        tbody.insertAdjacentHTML('beforeend', html);
    });
})();
