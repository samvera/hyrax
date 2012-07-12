$(function() {

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
        success: function( data ) {           response( $.map( data.geonames, function( item ) { 
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
            }   
          }));
        }   
      }); 
    },  
    minLength: 2,
  }
  $("#generic_file_based_near").autocomplete(cities_autocomplete_opts);


  function get_autocomplete_opts(field)
  {
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
      }/* 
      select: function( event, ui ) {
        $("#selectedSubjects").append("<div class = 'selectedsubject'>" + ui.item.label+"<img id='killSubject' style='position:relative; left:10px' src='images/close_icon.gif'/><div id='hiddenId' style='display:none'>"+ui.item.value+"</div></div>");                
        $(this).val("");
        return false;
      }*/
    }   
    return autocomplete_opts;
  }
 
  var autocomplete_vocab = new Object();

  autocomplete_vocab.url_var =      ['subject', 'language'];   // the url variable to pass to determine the vocab to attach to
  autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete
  autocomplete_vocab.add_btn_id = new Array(); // the id of the button pressed when adding an additional form element 

  // loop over the autocomplete fields and attach the 
  // events for autocomplete and create other array values for autocomplete
  for (var i=0; i < autocomplete_vocab.url_var.length; i++)
  {
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

  $('.adder').click(function() {
    //this.id = additional_N_submit
    //id for element to clone = additional_N_clone
    //id for element to append to = additional_N_elements
    var cloneId = this.id.replace("submit", "clone");
    var newId = this.id.replace("submit", "elements");
    var cloneElem = $('#'+cloneId).clone();

    //remove the button before adding the input
    //we don't want a button on each element being appended
    cloneElem.find('#'+this.id).remove();
    cloneElem.find('.formHelp').remove();

    //clear out the value for the element being appended
    //so the new element has a blank value
    cloneElem.find('input[type=text]').attr("value", "");

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

  // this will make the help text for a form element, displayable 
  // when focus is given, assuming there is a help element
  // help element id must be same id as the form element with a 
  // suffix of _help
  $('input[type=text], textarea').focus(function() {
       $("#"+this.id+"_help").css("display", "inline-block"); 
    });

  // hides the form help element when focus is lost
  $('input[type=text], textarea').focusout(function() {
       $("#"+this.id+"_help").css("display", "none"); 
      });

  $('.icon-plus').click(function() {
    //this.id format: "expand_NNNNNNNNNN"
    var a = this.id.split("expand_");
    if (a.length > 1)
    {
      docId = a[1]
      $("#detail_"+docId).toggle();
      if( $("#detail_"+docId).is(":hidden") ) {
        $("#expand_"+docId).attr("class", "icon-plus");
      }
      else {
        $("#expand_"+docId).attr("class", "icon-minus");
      }
    }
  })

  $('#add_descriptions').click(function() {
      $('#more_descriptions').show();
  });

  $('#new_user_permission_skel').attr('disabled', true);
  $('#new_group_permission_skel').attr('disabled', true);

  // dropdown of umgs on select enable the permission and add focus
  $('#new_group_name_skel').on('change', function() {
      // clear out any existing messages
    if ($('#new_group_name_skel :selected').index() != "0") {
      $('#new_group_permission_skel').attr('disabled', false);
      $('#new_group_permission_skel').focus();
    }
  });

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
          if (!data) {
            $('#directory_user_result').html('User id ('+un+ ') does not exist.'); 
            $('#new_user_name_skel').select();
            $('#new_user_permission_skel').val('none');
            $('#new_user_permission_skel').attr('disabled', true);
            return;
          }
          else {
            $('#new_user_permission_skel').attr('disabled', false);
            $('#new_user_permission_skel').focus();
          }
        },
      }); 

  });

  // dropdown of perms for users
  $('#new_user_permission_skel').on('change focus', function() {
      if($('#new_user_name_skel').val() == "" || $('#new_user_permission_skel :selected').index() == "0") {
        return;
      }
      var un = $('#new_user_name_skel').val();
      var perm_form = $('#new_user_permission_skel').val();
      var perm = $('#new_user_permission_skel :selected').text();
      // clear out the elements to add more
      $('#new_user_name_skel').val('');
      $('#new_user_permission_skel').val('none');

      addPerm(un, perm_form, perm, 'new_user_name');
  });

  // dropdown of perms for groups
  $('#new_group_permission_skel').on('change focus', function() {
      if ($('#new_group_name_skel :selected').index() == "0" || $('#new_group_permission_skel :selected').index() == "0") {
        return;
      }
      var cn = $('#new_group_name_skel').val();
      var perm_form = $('#new_group_permission_skel').val();
      var perm = $('#new_group_permission_skel :selected').text();
      // clear out the elements to add more
      $('#new_group_name_skel').val('');
      $('#new_group_permission_skel').val('none');
      
      addPerm(cn, perm_form, perm, 'new_group_name');
  });

  function addPerm(un, perm_form, perm, perm_type) 
  { 
      var tr = $(document.createElement('tr'));
      var td1 = $(document.createElement('td'));
      var td2 = $(document.createElement('td'));
      var remove = $('<button class="close btn-inverse">X</button>');

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
      $('#file_permissions').append(tr);
      tr.effect("highlight", {}, 3000);
  }

  $('#edit_descriptions_link').on('click', function() {
    $('#edit_descriptions_link').attr('class', 'active');
    $('#edit_versioning_link').attr('class', '');
    $('#edit_permissions_link').attr('class', '');

    $('#descriptions_display').show();
    $('#versioning_display').hide();
    $('#permissions_display').hide();
    $('#permissions_submit').hide();
  });

  $('#edit_versioning_link').on('click', function() {
    $('#edit_descriptions_link').attr('class', '');
    $('#edit_versioning_link').attr('class', 'active');
    $('#edit_permissions_link').attr('class', '');

    $('#descriptions_display').hide();
    $('#versioning_display').show();
    $('#permissions_display').hide();
    $('#permissions_submit').hide();
  });

  $('#edit_permissions_link').on('click', function() {
    $('#edit_permissions_link').attr('class', 'active');
    $('#edit_versioning_link').attr('class', '');
    $('#edit_descriptions_link').attr('class', '');

    $('#descriptions_display').hide();
    $('#versioning_display').hide();
    $('#permissions_display').show();
    $('#permissions_submit').show();
  });


});
