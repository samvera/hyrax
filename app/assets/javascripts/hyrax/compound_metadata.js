// Behavior for compound metadata fields on resource edit forms (add/remove row,
// work_or_url select2). Event-delegated so dynamically-added rows need no
// rebinding. The sentinel guards against the IIFE running twice (Turbolinks
// re-evaluates module scripts on some navigation paths), which would stack
// duplicate listeners. Mirrors hyrax/redirects.js.
(function () {
    if (document.hyraxCompoundsBound) { return; }
    document.hyraxCompoundsBound = true;

    // Bind select2 to a `work_or_url` sub-property. The v3 API (Hyrax bundles
    // select2-rails 3.x) binds to a hidden input; createSearchChoice lets a
    // typed external URL be selected as-is.
    function bindWorkOrUrlInputs(root) {
        if (typeof jQuery === 'undefined' || !jQuery.fn.select2) return;
        jQuery(root).find('[data-hyrax-compound-work-input]').each(function() {
            var $el = jQuery(this);
            if ($el.hasClass('select2-offscreen') || $el.data('select2')) return; // already bound
            $el.select2({
                width: '100%',
                allowClear: true,
                placeholder: 'Search for a work or enter a URL',
                minimumInputLength: 2,
                // Let a typed value (e.g. an external URL) be selected as-is.
                createSearchChoice: function(term) {
                    return { id: term, text: term };
                },
                // Render the current value's label (work title or the URL) on load.
                initSelection: function(element, callback) {
                    var val = element.val();
                    if (!val) return;
                    callback({ id: val, text: element.data('label') || val });
                },
                ajax: {
                    url: $el.data('autocomplete-url'),
                    dataType: 'json',
                    quietMillis: 250,
                    data: function(term, page) { return { q: term }; },
                    results: function(data, page) {
                        return {
                            results: data.map(function(obj) {
                                return { id: obj.id, text: [].concat(obj.label)[0] };
                            })
                        };
                    }
                }
            });
        });
    }

    // Bind saved rows once the DOM is ready (at script-eval time the form
    // inputs don't exist yet, so the select2 would never attach). Covers both a
    // fresh load and Turbolinks navigation.
    function bindAll() { bindWorkOrUrlInputs(document); }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bindAll);
    } else {
        bindAll();
    }
    document.addEventListener('turbolinks:load', bindAll);

    // Remove a compound row: persisted rows are hidden + their `_destroy` flag
    // flipped so the server-side populator drops them; unsaved rows are
    // removed from the DOM outright. Returns true when the click was a
    // remove-row gesture (so the dispatcher can stop further handling).
    function handleRemoveClick(event) {
        var removeButton = event.target.closest('[data-hyrax-compound-remove-row]');
        if (!removeButton) { return false; }
        var row = removeButton.closest('[data-hyrax-compound-row]');
        if (!row) { return true; }
        var destroyFlag = row.querySelector('[data-hyrax-compound-destroy-flag]');
        if (destroyFlag && destroyFlag.value !== undefined) {
            destroyFlag.value = '1';
            row.style.display = 'none';
        } else {
            row.parentNode.removeChild(row);
        }
        return true;
    }

    // Add a compound row: clone the section's template, swap the `__INDEX__`
    // placeholder for a monotonic counter, append, and bind any select2
    // inputs the new row carries. Returns true when the click was an
    // add-row gesture.
    function handleAddClick(event) {
        var addButton = event.target.closest('[data-hyrax-compound-add-row]');
        if (!addButton) { return false; }
        var section = addButton.closest('[data-hyrax-compound]');
        if (!section) { return true; }
        var template = section.querySelector('[data-hyrax-compound-row-template]');
        var rowsHost = section.querySelector('[data-hyrax-compound-rows]');
        if (!template || !rowsHost) { return true; }

        var nextIndex = parseInt(section.dataset.nextIndex, 10);
        if (isNaN(nextIndex)) {
            nextIndex = rowsHost.querySelectorAll('[data-hyrax-compound-row]').length;
        }
        var html = template.innerHTML.replace(/__INDEX__/g, nextIndex);
        rowsHost.insertAdjacentHTML('beforeend', html);
        bindWorkOrUrlInputs(rowsHost.lastElementChild || rowsHost);
        section.dataset.nextIndex = String(nextIndex + 1);
        return true;
    }

    document.addEventListener('click', function (event) {
        if (handleRemoveClick(event)) { return; }
        handleAddClick(event);
    });
}());
