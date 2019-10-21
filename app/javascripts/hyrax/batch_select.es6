export let initialize_batch_selected = () =>
{
    $('input.submits-batches').on('click', ({target}) => {
        let form = $(target).closest("form");
        $.map($(".batch_document_selector:checked"), (document, i) => {
            let id = document.value;
            if (form.children("input[value='" + id + "']").length === 0)
                form.append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="' + id + '" />');
        });
    });
}
