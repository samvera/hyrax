Blacklight.onLoad(function() {
    // toggle button on or off based on boxes being clicked
    $(".batch_document_selector, .batch_document_selector_all").bind('click', function(e) {
        var n = $(".batch_document_selector:checked").length;
        if (n>0 || $('input#check_all')[0].checked) {
            $('.sort-toggle').hide();
        } else {
            $('.sort-toggle').show();
        }

    });
});

