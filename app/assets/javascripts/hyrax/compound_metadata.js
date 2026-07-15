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

    // Unlike the work_or_url / linked_record pickers (hidden input + ajax), this
    // binds a native <select> whose full option list is already in the DOM, so
    // select2 filters client-side.
    function bindControlledSelects(root) {
        if (typeof jQuery === 'undefined' || !jQuery.fn.select2) return;
        jQuery(root).find('[data-hyrax-compound-controlled]').each(function() {
            var $el = jQuery(this);
            if ($el.hasClass('select2-offscreen') || $el.data('select2')) return; // already bound

            $el.select2({
                width: '100%',
                // A single select carries a blank option (include_blank), so
                // allowClear gives it an "x"; a multiple has none and needs a
                // placeholder to prompt.
                allowClear: !$el.prop('multiple'),
                placeholder: $el.data('placeholder') || ''
            });
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
    function bindAll() { bindWorkOrUrlInputs(document); bindControlledSelects(document); }
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
        if (!wrap) return;
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        if (!form) return;
        form.classList.remove('d-none');
        form.hidden = false;
        var firstText = form.querySelector('input[data-create-field]');
        var term = jQuery(wrap).data('lastTerm');
        if (firstText && term && !firstText.value) firstText.value = term;
    }

    function closeCreateForm(wrap) {
        if (!wrap) return;
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        if (form) { form.classList.add('d-none'); form.hidden = true; }
    }

    function submitCreateForm(wrap) {
        if (!wrap) return;
        var url = wrap.getAttribute('data-create-url');
        var form = wrap.querySelector('[data-hyrax-linked-record-create-form]');
        if (!url || !form) return;
        var errors = form.querySelector('[data-hyrax-linked-record-create-errors]');
        var record = {};
        // Scalar create-fields: one value each. Skip inputs that live inside a
        // group (those are collected per-row below).
        form.querySelectorAll('[data-create-field]').forEach(function(input) {
            if (input.closest('[data-create-group]')) return;
            record[input.getAttribute('data-create-field')] = input.value;
        });
        // Repeatable create-fields: collected from their rows (the <template>
        // row is inert). A group field becomes an array of {subfield: value}
        // hashes; a repeatable scalar (data-create-scalar) becomes a plain array
        // of strings. Blank rows are skipped.
        form.querySelectorAll('[data-create-group]').forEach(function(group) {
            var name = group.getAttribute('data-create-group');
            var scalar = group.getAttribute('data-create-scalar') === 'true';
            var rows = [];
            group.querySelectorAll('[data-create-group-rows] [data-create-group-row]').forEach(function(rowEl) {
                if (scalar) {
                    var input = rowEl.querySelector('[data-create-subfield]');
                    if (input && input.value) rows.push(input.value);
                } else {
                    var row = {};
                    var any = false;
                    rowEl.querySelectorAll('[data-create-subfield]').forEach(function(sub) {
                        row[sub.getAttribute('data-create-subfield')] = sub.value;
                        if (sub.value) any = true;
                    });
                    if (any) rows.push(row);
                }
            });
            record[name] = rows;
        });

        // Show server-supplied messages (already localized), falling back to the
        // localized default the partial set on `data-default-message`.
        function showError(messages) {
            if (!errors) return;
            var fallback = errors.getAttribute('data-default-message') || 'Could not create';
            var list = [].concat(messages || []).filter(Boolean);
            errors.textContent = (list.length ? list : [fallback]).join(', ');
            errors.classList.remove('d-none');
        }

        var token = (document.querySelector('meta[name="csrf-token"]') || {}).content;
        fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token || '', 'Accept': 'application/json' },
            body: JSON.stringify({ record: record })
        }).then(function(resp) {
            // A 5xx (e.g. a DB-level failure) returns an HTML error page, not
            // JSON; tolerate a non-JSON body so the form still surfaces a message
            // instead of silently swallowing the parse error.
            return resp.text().then(function(text) {
                var body;
                try { body = JSON.parse(text); } catch (e) { body = {}; }
                return { ok: resp.ok, body: body };
            });
        }).then(function(result) {
            if (result.ok) {
                // Select the new record in the picker (select2 v3 takes {id,text}).
                var $input = jQuery(wrap).find('[data-hyrax-linked-record-input]');
                $input.select2('data', { id: result.body.id, text: result.body.label });
                closeCreateForm(wrap);
                var $add = jQuery(wrap).find('[data-hyrax-linked-record-add]');
                $add.addClass('d-none').prop('hidden', true);
            } else {
                showError(result.body.errors);
            }
        }).catch(function() {
            // No-arg showError falls back to the localized default message.
            showError();
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
        // Repeatable group create-field: add a row (clone the template) / remove a row.
        var groupAdd = event.target.closest('[data-create-group-add]');
        if (groupAdd) {
            var group = groupAdd.closest('[data-create-group]');
            var template = group.querySelector('[data-create-group-row-template]');
            var rows = group.querySelector('[data-create-group-rows]');
            if (template && rows) rows.appendChild(template.content.cloneNode(true));
            return;
        }
        var groupRemove = event.target.closest('[data-create-group-remove]');
        if (groupRemove) {
            var groupRows = groupRemove.closest('[data-create-group-rows]');
            var thisRow = groupRemove.closest('[data-create-group-row]');
            // Keep at least one row present; clear it instead of removing the last.
            if (groupRows && groupRows.querySelectorAll('[data-create-group-row]').length > 1) {
                thisRow.parentNode.removeChild(thisRow);
            } else if (thisRow) {
                thisRow.querySelectorAll('[data-create-subfield]').forEach(function(i) { i.value = ''; });
            }
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
        // Cloned rows are fresh DOM, so re-run the select2 bindings.
        bindWorkOrUrlInputs(rowsHost.lastElementChild || rowsHost);
        bindControlledSelects(rowsHost.lastElementChild || rowsHost);
        section.dataset.nextIndex = String(nextIndex + 1);
    });
})();
