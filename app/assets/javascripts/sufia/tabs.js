$(function() {
  // called from edit object view
  $('#edit_descriptions_link').on('click', function(e) {
      e.preventDefault();
      descriptions_tab();
    });

  // called from edit object view
  $('#edit_versioning_link').on('click', function(e) {
      e.preventDefault();
      versions_tab();
    });

  // called from edit object view
  $('#edit_permissions_link').on('click', function(e) {
      e.preventDefault();
      permissions_tab();
    });
});

// all called from edit object view
// when permissions link is clicked on edit object
function permissions_tab ()
{
    $('#edit_permissions_link').attr('class', 'active');
    $('#edit_versioning_link').attr('class', '');
    $('#edit_descriptions_link').attr('class', '');

    $('#descriptions_display').hide();
    $('#versioning_display').hide();
    $('#permissions_display').show();
    $('#permissions_submit').show();
}
// when versions link is clicked on edit object
function versions_tab()
{
    $('#edit_descriptions_link').attr('class', '');
    $('#edit_versioning_link').attr('class', 'active');
    $('#edit_permissions_link').attr('class', '');

    $('#descriptions_display').hide();
    $('#versioning_display').show();
    $('#permissions_display').hide();
    $('#permissions_submit').hide();
}
// when descriptions link is clicked on edit object
function descriptions_tab ()
{
    $('#edit_descriptions_link').attr('class', 'active');
    $('#edit_versioning_link').attr('class', '');
    $('#edit_permissions_link').attr('class', '');

    $('#descriptions_display').show();
    $('#versioning_display').hide();
    $('#permissions_display').hide();
    $('#permissions_submit').hide();
}

