  /*
   *
   *
   * permissions
   *
   * ids that end in 'skel' are only used as elements
   * to clone into real form elements that are then
   * submitted
   */

Blacklight.onLoad(function() {

  // Attach the user search select2 box to the permission form
  $("#new_user_name_skel").userSearch();

  // add button for new user
  $('#add_new_user_skel').on('click', function() {
      if ($('#new_user_name_skel').val() == "" || $('#new_user_permission_skel :selected').index() == "0") {
        $('#new_user_name_skel').focus();
        return false;
      }

      if ( ($('#new_user_name_skel').val()+$('.add-on').text()) == $('#file_owner').data('depositor') ) {
        $('#permissions_error_text').html("Cannot change depositor permissions.");
        $('#permissions_error').removeClass('hidden');
        $('#new_user_name_skel').val('');
        $('#new_user_name_skel').focus();
        return false;
      }

      if (!is_permission_duplicate($('#new_user_name_skel').val())) {
        $('#permissions_error_text').html("This user already has a permission.");
        $('#permissions_error').removeClass('hidden');
        $('#new_user_name_skel').focus();
        return false;
      }
      $('#permissions_error').html();
      $('#permissions_error').addClass('hidden');

      var user_name = $('#new_user_name_skel').val();
      var access = $('#new_user_permission_skel').val();
      var access_label = $('#new_user_permission_skel :selected').text();
      // clear out the elements to add more
      $('#new_user_name_skel').val('');
      $('#new_user_permission_skel').val('none');

      addPerm(user_name, access, access_label, 'user');
      return false;
  });

  // add button for new user
  $('#add_new_group_skel').on('click', function() {
      if ($('#new_group_name_skel :selected').index() == "0" || $('#new_group_permission_skel :selected').index() == "0") {
        $('#new_group_name_skel').focus();
        return false;
      }
      var group_name = $('#new_group_name_skel').val();
      var access = $('#new_group_permission_skel').val();
      var access_label = $('#new_group_permission_skel :selected').text();

      if (!is_permission_duplicate($('#new_group_name_skel').val())) {
        $('#permissions_error_text').html("This group already has a permission.");
        $('#permissions_error').removeClass('hidden');
        $('#new_group_name_skel').focus();
        return false;
      }
      $('#permissions_error').html();
      $('#permissions_error').addClass('hidden');
      // clear out the elements to add more
      $('#new_group_name_skel').val('');
      $('#new_group_permission_skel').val('none');

      addPerm(group_name, access, access_label, 'group');
      return false;
  });

  // when user clicks on visibility, update potential access levels
  $("input[name='visibility']").on("change", set_access_levels);

	$('#generic_file_permissions_new_group_name').change(function (){
      var edit_option = $("#generic_file_permissions_new_group_permission option[value='edit']")[0];
	    if (this.value.toUpperCase() == 'PUBLIC') {
	       edit_option.disabled =true;
	    } else {
           edit_option.disabled =false;
	    }

	});

  function addPerm(agent_name, access, access_label, agent_type)
  {
      showPermissionNote();

      var tr = createPermissionRow(agent_name, access_label);
      addHiddenPermField(tr, agent_type, agent_name, access);
      $('#file_permissions').after(tr);
      tr.effect("highlight", {}, 3000);
  }

  function createPermissionRow(agent_name, access_label) {
      var tr = $(document.createElement('tr'));
      var td1 = $(document.createElement('td'));
      var td2 = $(document.createElement('td'));
      var remove_button = $('<button class="btn close">X</button>');

      td1.html('<label class="control-label">' + agent_name + '</label>');
      td2.html(access_label);
      td2.append(remove_button);
      remove_button.click(function () {
        tr.remove();
      });

      return tr.append(td1).append(td2);
  }

  function addHiddenPermField(element, type, name, access) {
      var prefix = 'generic_file[permissions_attributes][' + nextIndex() + ']';
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[type]',
          value: type
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[name]',
          value: name
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[access]',
          value: access
      }).appendTo(element);
  }

  function nextIndex() {
      return $('#file_permissions').parent().children().size() - 1;
  }

  $('.remove_perm').on('click', function(evt) {
       evt.preventDefault();
       var top = $(this).parent().parent();
       top.addClass('hidden'); // do not show the block
       addDestroyField(top, $(this).attr('data-index'));
       showPermissionNote();
  });

  function showPermissionNote() {
     $('#save_perm_note').removeClass('hidden');
  }

  function addDestroyField(element, index) {
      $('<input>').attr({
          type: 'hidden',
          name: 'generic_file[permissions_attributes][' + index + '][_destroy]',
          value: 'true'
      }).appendTo(element);
  }

});

// return the files visibility level (institution, open, restricted);
function get_visibility() {
  return $("input[name='visibility']:checked").val();
}

/*
 * if visibility is Open or Institution then we can't selectively
 * set other users/groups to 'read' (it would be over ruled by the
 * visibility of Open or Institution) so disable the Read option
 */
function set_access_levels() {
  var vis = get_visibility();
  var enabled_disabled = false;
  if (vis == "open" || vis == "psu") {
    enabled_disabled = true;
  }
  $('#new_group_permission_skel option[value=read]').attr("disabled", enabled_disabled);
  $('#new_user_permission_skel option[value=read]').attr("disabled", enabled_disabled);
  var perms_sel = $("select[name^='generic_file[permissions]']");
  $.each(perms_sel, function(index, sel_obj) {
    $.each(sel_obj, function(j, opt) {
      if( opt.value == "read") {
        opt.disabled = enabled_disabled;
      }
    });
  });
}

/*
 * make sure the permission being applied is not for a user/group
 * that already has a permission.
 */
function is_permission_duplicate(user_or_group_name)
{
  s = "[" + user_or_group_name + "]";
  var patt = new RegExp(preg_quote(s), 'gi');
  var perms_input = $("input[name^='generic_file[permissions]']");
  var perms_sel = $("select[name^='generic_file[permissions]']");
  var flag = 1;
  perms_input.each(function(index, form_input) {
      // if the name is already being used - return false (not valid)
      if (patt.test(form_input.name)) {
        flag = 0;
      }
    });
  if (flag) {
    perms_sel.each(function(index, form_input) {
      // if the name is already being used - return false (not valid)
      if (patt.test(form_input.name)) {
        flag = 0;
      }
    });
  }
  // putting a return false inside the each block
  // was not working.  Not sure why would seem better
  // rather than setting this flag var
  return (flag ? true : false);
}
