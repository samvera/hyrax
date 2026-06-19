// Behavior for compound metadata fields on resource edit forms (add/remove row,
// work_or_url and linked_record select2 pickers). Event-delegated so
// dynamically-added rows need no rebinding. The sentinel guards against the IIFE
// running twice (Turbolinks re-evaluates module scripts on some navigation
// paths), which would stack duplicate listeners. Mirrors hyrax/redirects.js.
(function() {
    if (document.hyraxCompoundsBound) return;
    document.hyraxCompoundsBound = true;

    // Bind select2 to a `work_or_url` or `linked_record` sub-property. The v3
    // API (Hyrax bundles select2-rails 3.x) binds to a hidden input. A
    // work_or_url picker lets a typed external URL be selected as-is
    // (createSearchChoice); a linked_record picker resolves only to a row id, so
    // a typed value is not a valid selection — and an empty result set reveals
    // its "Add new" affordance instead.
    function bindWorkOrUrlInputs(root) {
        if (typeof jQuery === 'undefined' || !jQuery.fn.select2) return;
        jQuery(root).find('[data-hyrax-compound-work-input]').each(function() {
            var $el = jQuery(this);
            if ($el.hasClass('select2-offscreen') || $el.data('select2')) return; // already bound

            var isLinkedRecord = $el.is('[data-hyrax-linked-record-input]');
            var lastTerm = '';
            // Capture the wrapper now, before select2 restructures the DOM around
            // the input, so the no-results reveal doesn't depend on .closest()
            // still resolving after binding.
            var wrapEl = isLinkedRecord ? $el.closest('[data-hyrax-linked-record]')[0] : null;

            var options = {
                width: '100%',
                allowClear: true,
                // Per-field prompt via data-placeholder (work_or_url omits it and
                // keeps the original text).
                placeholder: $el.data('placeholder') || 'Search for a work or enter a URL',
                minimumInputLength: 2,
                // Render the current value's label (work title / record label /
                // URL) on load.
                initSelection: function(element, callback) {
                    var val = element.val();
                    if (!val) return;
                    callback({ id: val, text: element.data('label') || val });
                },
                ajax: {
                    url: $el.data('autocomplete-url'),
                    dataType: 'json',
                    quietMillis: 250,
                    data: function(term, page) { lastTerm = term; return { q: term }; },
                    results: function(data, page) {
                        // For a creatable linked_record, surface the "Add new"
                        // trigger when the search came back empty.
                        if (isLinkedRecord) toggleAddNew(wrapEl, data.length === 0, lastTerm);
                        return {
                            results: data.map(function(obj) {
                                return { id: obj.id, text: [].concat(obj.label)[0] };
                            })
                        };
                    }
                }
            };

            // Only work_or_url accepts a free-typed value as its selection.
            if (!isLinkedRecord) {
                options.createSearchChoice = function(term) { return { id: term, text: term }; };
            }

            $el.select2(options);
        });
    }

    // Show/hide the "Add new" trigger for a creatable linked_record when a
    // search returned no matches; stash the typed term to prefill the form.
    // `wrapEl` is the [data-hyrax-linked-record] wrapper captured at bind time.
    function toggleAddNew(wrapEl, noResults, term) {
        if (!wrapEl || wrapEl.getAttribute('data-creatable') !== 'true') return;
        var $wrap = jQuery(wrapEl);
        var $add = $wrap.find('[data-hyrax-linked-record-add]');
        if (!$add.length) return;
        $wrap.data('lastTerm', term || '');
        if (noResults) {
            $add.removeClass('d-none').prop('hidden', false);
        } else {
            $add.addClass('d-none').prop('hidden', true);
        }
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

    // Reveal the inline create form (prefilling the first text field with the
    // typed search term), POST it to the source's create endpoint, and on
    // success select the new record in the picker.
    function openCreateForm(wrap) {
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        if (!form) return;
        form.classList.remove('d-none');
        form.hidden = false;
        var firstText = form.querySelector('input[data-create-field]');
        var term = jQuery(wrap).data('lastTerm');
        if (firstText && term && !firstText.value) firstText.value = term;
    }

    function closeCreateForm(wrap) {
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        if (form) { form.classList.add('d-none'); form.hidden = true; }
    }

    function submitCreateForm(wrap) {
        var url = wrap.getAttribute('data-create-url');
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        var errors = form.querySelector('[data-hyrax-linked-record-create-errors]');
        var record = {};
        form.querySelectorAll('[data-create-field]').forEach(function(input) {
            record[input.getAttribute('data-create-field')] = input.value;
        });

        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content;
        fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token || '', 'Accept': 'application/json' },
            body: JSON.stringify({ record: record })
        }).then(function(resp) {
            return resp.json().then(function(body) { return { ok: resp.ok, body: body }; });
        }).then(function(result) {
            if (result.ok) {
                // Select the new record in the picker (select2 v3 takes {id,text}).
                var $input = jQuery(wrap).find('[data-hyrax-linked-record-input]');
                $input.select2('data', { id: result.body.id, text: result.body.label });
                closeCreateForm(wrap);
                var $add = jQuery(wrap).find('[data-hyrax-linked-record-add]');
                $add.addClass('d-none').prop('hidden', true);
            } else if (errors) {
                errors.textContent = [].concat(result.body.errors || ['Could not create']).join(', ');
                errors.classList.remove('d-none');
            }
        });
    }

    document.addEventListener('click', function(event) {
        // --- linked_record inline create affordance ---
        var addTrigger = event.target.closest('[data-hyrax-linked-record-add]');
        if (addTrigger) {
            openCreateForm(addTrigger.closest('[data-hyrax-linked-record]'));
            return;
        }
        var createSubmit = event.target.closest('[data-hyrax-linked-record-create-submit]');
        if (createSubmit) {
            submitCreateForm(createSubmit.closest('[data-hyrax-linked-record]'));
            return;
        }
        var createCancel = event.target.closest('[data-hyrax-linked-record-create-cancel]');
        if (createCancel) {
            closeCreateForm(createCancel.closest('[data-hyrax-linked-record]'));
            return;
        }

        var removeButton = event.target.closest('[data-hyrax-compound-remove-row]');
        if (removeButton) {
            var row = removeButton.closest('[data-hyrax-compound-row]');
            if (!row) return;
            var destroyFlag = row.querySelector('[data-hyrax-compound-destroy-flag]');
            if (destroyFlag && destroyFlag.value !== undefined) {
                // Persisted rows: flip the _destroy flag and hide so the
                // populator drops the row server-side.
                destroyFlag.value = '1';
                row.style.display = 'none';
            } else {
                row.parentNode.removeChild(row);
            }
            return;
        }

        var addButton = event.target.closest('[data-hyrax-compound-add-row]');
        if (!addButton) return;
        var section = addButton.closest('[data-hyrax-compound]');
        if (!section) return;
        var template = section.querySelector('[data-hyrax-compound-row-template]');
        var rowsHost = section.querySelector('[data-hyrax-compound-rows]');
        if (!template || !rowsHost) return;

        // Monotonic counter on the section; never recycle an index after a
        // row is removed. Fallback to row count when the attribute is missing.
        var nextIndex = parseInt(section.dataset.nextIndex, 10);
        if (isNaN(nextIndex)) {
            nextIndex = rowsHost.querySelectorAll('[data-hyrax-compound-row]').length;
        }
        var html = template.innerHTML.replace(/__INDEX__/g, nextIndex);
        rowsHost.insertAdjacentHTML('beforeend', html);
        // Bind select2 on any work_or_url / linked_record inputs in the new row.
        bindWorkOrUrlInputs(rowsHost.lastElementChild || rowsHost);
        section.dataset.nextIndex = String(nextIndex + 1);
    });
})();
