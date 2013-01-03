/*
Copyright © 2012 The Pennsylvania State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

//= require jquery-ui-1.9.2/jquery.ui.core
//= require jquery-ui-1.9.2/jquery.ui.widget
//= require jquery-ui-1.9.2/jquery.ui.menu
//= require jquery-ui-1.9.2/jquery.ui.autocomplete

//= require bootstrap-dropdown
//= require bootstrap-button
//= require bootstrap-modal
//= require bootstrap-collapse
//= require bootstrap-tooltip
//= require bootstrap-popover

//= require batch_edit
//= require terms_of_service
//= require fileupload
//= require video
//= require audio.min
//= require jquery.validate

//over ride the blacklight default to submit
//form when sort by or show per page change
Blacklight.do_select_submit = function() {
  $(Blacklight.do_select_submit.selector).each(function() {
        var select = $(this);
        select.closest("form").find("input[type=submit]").show();
        select.bind("change", function() {
          return false;
        });
    });
};
Blacklight.do_select_submit.selector = "form.sort select, form.per_page select";

// short hand for $(document).ready();
$(function() {

  // set up global batch edit options to override the ones in the gem 
  window.batch_edits_options = { checked_label: "",unchecked_label: "",progress_label: "",status_label: "",css_class: "batch_toggle"};
 

  // bootstrap alerts are closed this function
  $('.alert .close').live('click',function(){
    $(this).parent().hide();
  });

  $.fn.selectRange = function(start, end) {
    return this.each(function() {
        if (this.setSelectionRange) {
            this.focus();
            this.setSelectionRange(start, end);
        } else if (this.createTextRange) {
            var range = this.createTextRange();
            range.collapse(true);
            range.moveEnd('character', end);
            range.moveStart('character', start);
            range.select();
        }
    });
  };
    // there are two levels of vocabulary auto complete.
    // currently we have this externally hosted vocabulary
    // for geonames.  I'm not going to make these any easier
    // to implement for an external url (it's all hard coded)
    // because I'm guessing we'll get away from the hard coding
  var cities_autocomplete_opts = {
    source: function( request, response ) {
      $.ajax( {
        url: "http://ws.geonames.org/searchJSON",
        dataType: "jsonp",
        data: {
          featureClass: "P",
          style: "full",
          maxRows: 12,
          name_startsWith: request.term
        },
        success: function( data ) {        response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName
            };
          }));
        },
      });
    },
    minLength: 2
  };
  //$("#generic_file_based_near").autocomplete(cities_autocomplete_opts);
  $("#generic_file_based_near").autocomplete(get_autocomplete_opts("location"));


  function get_autocomplete_opts(field) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/authorities/generic_files/" + field, {
          q: request.term
        }, response );
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      }
      /*
      select: function( event, ui ) {
        $("#selectedSubjects").append("<div class = 'selectedsubject'>" + ui.item.label+"<img id='killSubject' style='position:relative; left:10px' src='images/close_icon.gif'/><div id='hiddenId' style='display:none'>"+ui.item.value+"</div></div>");
        $(this).val("");
        return false;
      }*/
    };
    return autocomplete_opts;
  }

  var autocomplete_vocab = new Object();

  autocomplete_vocab.url_var = ['subject', 'language'];   // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete
  autocomplete_vocab.add_btn_id = new Array(); // the id of the button pressed when adding an additional form element

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
    autocomplete_vocab.field_name.push('generic_file_' + autocomplete_vocab.url_var[i]);
    autocomplete_vocab.add_btn_id.push('additional_' + autocomplete_vocab.url_var[i] + '_submit');
    // autocompletes
    $("#" + autocomplete_vocab.field_name[i])
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete( get_autocomplete_opts(autocomplete_vocab.url_var[i]) );

  }

  /*
   * adds additional metadata elements
   */
  $('.adder').click(function() {
    //this.id = additional_N_submit
    //id for element to clone = additional_N_clone
    //id for element to append to = additional_N_elements
    //var cloneId = this.id.replace("submit", "clone");
    //var newId = this.id.replace("submit", "elements");
    var cloneId = this.id.replace("submit", "clone");
    var newId = this.id.replace("submit", "elements");
    var cloneElem = $('#'+cloneId).clone();
    // change the add button to a remove button
    var plusbttn = cloneElem.find('#'+this.id);
    //plusbttn.attr("value","-");
    plusbttn.html('-<span class="accessible-hidden">remove this '+ this.name.replace("_", " ") +'</span>');
    plusbttn.on('click',removeField);

    // remove the help tag on subsequent added fields
    cloneElem.find('.formHelp').remove();
    cloneElem.find('i').remove();
    cloneElem.find('.modal-div').remove();

    //clear out the value for the element being appended
    //so the new element has a blank value
    cloneElem.find('input[type=text]').attr("value", "");
    cloneElem.find('input[type=text]').attr("required", false);

    // should we attach an auto complete based on the input
    if (this.id == 'additional_based_near_submit') {
      cloneElem.find('input[type=text]').autocomplete(cities_autocomplete_opts);
    }
    else if ( (index = $.inArray(this.id, autocomplete_vocab.add_btn_id)) != -1 ) {
      cloneElem.find('input[type=text]').autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
    }

    $('#'+newId).append(cloneElem);
    cloneElem.find('input[type=text]').focus();
    return false;
  });

  $('.remover').click(removeField);

  function removeField () {
    // get parent and remove it
    $(this).parent().remove();
    return false;
  }

  // show/hide more information on the dashboard when clicking
  // plus/minus
  $('.icon-plus').on('click', function() {
    //this.id format: "expand_NNNNNNNNNN"
    var a = this.id.split("expand_");
    if (a.length > 1) {
      var docId = a[1];
      $("#detail_"+docId).toggle();
      if( $("#detail_"+docId).is(":hidden") ) {
        $("#expand_"+docId).attr("class", "icon-plus icon-large");
      }
      else {
        $("#expand_"+docId).attr("class", "icon-minus icon-large");
      }
    }
    return false;
  });

  $('#add_descriptions').click(function() {
      $('#more_descriptions').show();
      $('#add_descriptions').hide();
      return false;
  });

  $("a[rel=popover]").click(function() { return false;});


  /*
   *
   *
   * permissions
   *
   * ids that end in 'skel' are only used as elements
   * to clone into real form elements that are then
   * submitted
   */

  // input for uids -  attach function to verify uid
  $('#new_user_name_skel').on('blur', function() {
      // clear out any existing messages
      $('#directory_user_result').html('');
      var un = $('#new_user_name_skel').val();
      var perm = $('#new_user_permission_skel').val();
      if ( $.trim(un).length == 0 ) {
        return;
      }
      $.ajax( {
        url: "/directory/user/" + un,
        success: function( data ) {
          if (data != null) {
            if (!data.length) {
              $('#directory_user_result').html('User id ('+un+ ') does not exist.');
              $('#new_user_name_skel').select();
              $('#new_user_permission_skel').val('none');
              return;
            }
            else {
              $('#new_user_permission_skel').focus();
            }
          }
        }
      });

  });


  // add button for new user
  $('#add_new_user_skel').on('click', function() {
      if ($('#new_user_name_skel').val() == "" || $('#new_user_permission_skel :selected').index() == "0") {
        $('#new_user_name_skel').focus();
        return false;
      }

      if ($('#new_user_name_skel').val() == $('#file_owner').html()) {
        $('#permissions_error_text').html("Cannot change owner permissions.");
        $('#permissions_error').show();
        $('#new_user_name_skel').val('');
        $('#new_user_name_skel').focus();
        return false;
      }

      if (!is_permission_duplicate($('#new_user_name_skel').val())) {
        $('#permissions_error_text').html("This user already has a permission.");
        $('#permissions_error').show();
        $('#new_user_name_skel').focus();
        return false;
      }
      $('#permissions_error').html();
      $('#permissions_error').hide();

      var un = $('#new_user_name_skel').val();
      var perm_form = $('#new_user_permission_skel').val();
      var perm = $('#new_user_permission_skel :selected').text();
      // clear out the elements to add more
      $('#new_user_name_skel').val('');
      $('#new_user_permission_skel').val('none');

      addPerm(un, perm_form, perm, 'new_user_name');
      return false;
  });

  // add button for new user
  $('#add_new_group_skel').on('click', function() {
      if ($('#new_group_name_skel :selected').index() == "0" || $('#new_group_permission_skel :selected').index() == "0") {
        $('#new_group_name_skel').focus();
        return false;
      }
      var cn = $('#new_group_name_skel').val();
      var perm_form = $('#new_group_permission_skel').val();
      var perm = $('#new_group_permission_skel :selected').text();

      if (!is_permission_duplicate($('#new_group_name_skel').val())) {
        $('#permissions_error_text').html("This group already has a permission.");
        $('#permissions_error').show();
        $('#new_group_name_skel').focus();
        return false;
      }
      $('#permissions_error').html();
      $('#permissions_error').hide();
      // clear out the elements to add more
      $('#new_group_name_skel').val('');
      $('#new_group_permission_skel').val('none');

      addPerm(cn, perm_form, perm, 'new_group_name');
      return false;
  });

  function addPerm(un, perm_form, perm, perm_type)
  {
      var tr = $(document.createElement('tr'));
      var td1 = $(document.createElement('td'));
      var td2 = $(document.createElement('td'));
      var remove = $('<button class="btn close">X</button>');

      $('#save_perm_note').show();

      $('#new_perms').append(td1);
      $('#new_perms').append(td2);

      td1.html('<label class="control-label">'+un+'</label>');
      td2.html(perm);
      td2.append(remove);
      remove.click(function () {
        tr.remove();
      });

      $('<input>').attr({
          type: 'hidden',
          name: 'generic_file[permissions]['+perm_type+']['+un+']',
          value: perm_form
        }).appendTo(td2);
      tr.append(td1);
      tr.append(td2);
      $('#file_permissions').after(tr);
      tr.effect("highlight", {}, 3000);
  }

  $('.remove_perm').on('click', function() {
     var top = $(this).parent().parent();
     top.hide(); // do not show the block
     top.find('.select_perm')[0].options[0].selected= true; // select the first otion which is none
     return false;

  });

  // called from edit object view
  $('#edit_descriptions_link').on('click', function() {
      descriptions_tab();
    });

  // called from edit object view
  $('#edit_versioning_link').on('click', function() {
    versions_tab();
    });

  // called from edit object view
  $('#edit_permissions_link').on('click', function() {
      permissions_tab();
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

  /*
   * facets lists
   */
    $("li.expandable").click(function(){
       $(this).next("ul").slideToggle();

       $(this).find('i').toggleClass("icon-chevron-down");
    });

    $("li.expandable_new").click(function(){
       $(this).find('i').toggleClass("icon-chevron-down");
    });

  /*
   * enlarge icons on hover- on dashboard
   */
  /*
  $('[class^="icon-"]').hover(
      //on mouseover
      function(){
        $(this).addClass("icon-large");
      },
      //on mouseout
      function() {
        $(this).removeClass("icon-large");
      });
      */



    $(".sorts-dash").click(function(){
       var itag =$(this).find('i');
       toggle_icon(itag);
       sort = itag.attr('class') == "icon-caret-down" ? itag.attr('id')+' desc':  itag.attr('id') +' asc';
       $('#sort').val(sort).selected = true;
       $(".icon-refresh").parent().click();
    });
    $(".sorts").click(function(){
       var itag =$(this).find('i');
       toggle_icon(itag);
        sort = itag.attr('class') == "icon-caret-down" ? itag.attr('id')+' desc':  itag.attr('id');
        $('input[name="sort"]').attr('value', sort);
        $(".icon-search").parent().click();
    });

}); //closing function at the top of the page



/*
 * begin functions
 */

function toggle_icon(itag){
       itag.toggleClass("icon-caret-down");
       itag.toggleClass("icon-caret-up");
}

// return the files visibility level (penn state, open, restricted);
function get_visibility(){
  return $("input[name='visibility']:checked").val()
}

/*
 * if visibility is Open or Penn State then we can't selectively
 * set other users/groups to 'read' (it would be over ruled by the
 * visibility of Open or Penn State) so disable the Read option
 */
function set_access_levels()
{
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

// is it worth checking to make sure users aren't filling up permissions that will be ignored.
// or when a user has already set a permission for a user then updates the visibility -- is it
// still relevant
function validate_existing_perms()
{
  var vis = get_visibility();
  if (vis == "open" || vis == "psu")
  {
    var perms = $("input[name^='generic_file[permissions]']");
    $.each(perms, function(index, form_input) {
        if (form_input.name != "generic_file[permissions][group][public]" && form_input.name != "generic_file[permissions][group][registered]") {
          if (form_input.value != 'edit') {
            alert("silly permission: " + form_input.name + " " + form_input.value );
          }
        }
    });
  }
}

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
function preg_quote( str ) {
    // http://kevin.vanzonneveld.net
    // +   original by: booeyOH
    // +   improved by: Ates Goral (http://magnetiq.com)
    // +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +   bugfixed by: Onno Marsman
    // *     example 1: preg_quote("$40");
    // *     returns 1: '\$40'
    // *     example 2: preg_quote("*RRRING* Hello?");
    // *     returns 2: '\*RRRING\* Hello\?'
    // *     example 3: preg_quote("\\.+*?[^]$(){}=!<>|:");
    // *     returns 3: '\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:'

    return (str+'').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
}


function initialize_audio() {

  if (navigator.userAgent.match("Chrome")){
      $('audio').each(function() {
         this.controls = true;
         //$(this).attr("controls","controls");
      });
  }else {
      $('audio').each(function() {
         $(this).attr("preload","auto");
      });
    audiojs.events.ready(function() {
          var as = audiojs.createAll({
                 imageLocation: '/assets/player-graphics.gif',
                 swfLocation: '/assets/audiojs.swf'
          });
    });
  };
}
