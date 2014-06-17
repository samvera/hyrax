Blacklight.onLoad(function () {
    $('#homeTabs a, #myTab a').click(function (e) {
        e.preventDefault();
        $(this).tab('show');
    });
    $('#homeTabs a:first, #myTab a:first').tab('show'); // Select first tab
});
