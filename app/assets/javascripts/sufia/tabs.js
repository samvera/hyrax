Blacklight.onLoad(function () {
  $('#homeTabs a, #myTab a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });
  $('#homeTabs a:first, #myTab a:first').tab('show'); // Select first tab

  // Show the tabs in GenericFile#edit given an anchor
  switch (window.location.hash.substring(1)) {
    case 'versioning_display':
      $('#edit_versioning_link a').tab('show');
      break;
    case 'descriptions_display':
      $('#edit_descriptions_link a').tab('show');
      break;
    case 'permissions_display':
      $('#edit_permissions_link a').tab('show');
      break;
  }
});
