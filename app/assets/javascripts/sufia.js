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
//= require jquery-ui-1.9.2/jquery.ui.position
//= require jquery-ui-1.9.2/jquery.ui.effect
//= require jquery-ui-1.9.2/jquery.ui.effect-highlight

//= require bootstrap-dropdown
//= require bootstrap-button
//= require bootstrap-modal
//= require bootstrap-collapse
//= require bootstrap-tooltip
//= require bootstrap-popover

//= require video
//= require audio.min
//= require jquery.validate
//= require swfobject
//= require jquery.zclip.min

//= require batch_edit
//= require terms_of_service
//= require fileupload
//= require sufia/permissions
//= require sufia/tabs
//= require sufia/trophy

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

function notify_update_link() {
   $('#notify_update_link').click();
}

// short hand for $(document).ready();
$(function() {

  // set up global batch edit options to override the ones in the gem 
  window.batch_edits_options = { checked_label: "",unchecked_label: "",progress_label: "",status_label: "",css_class: "batch_toggle"};

  setInterval(notify_update_link, 30*1000);

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
    var cloneId = this.id.replace("submit", "clone");
    var newId = this.id.replace("submit", "elements");
    var cloneElem = $('#'+cloneId).clone();
    // change the add button to a remove button
    var plusbttn = cloneElem.find('#'+this.id);
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
   * facets lists
   */
    $("li.expandable").click(function(){
       $(this).next("ul").slideToggle();

       $(this).find('i').toggleClass("icon-chevron-down");
    });

    $("li.expandable_new").click(function(){
       $(this).find('i').toggleClass("icon-chevron-down");
    });

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

