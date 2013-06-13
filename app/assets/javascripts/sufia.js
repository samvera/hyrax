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
//= require bootstrap-tab

//= require video
//= require audio.min
//= require jquery.validate
//= require swfobject
//= require ZeroClipboard.min

//= require batch_edit
//= require terms_of_service
//= require sufia/fileupload
//= require sufia/permissions
//= require sufia/trophy
//= require sufia/batch_select_all
//= require sufia/multiForm
//= require sufia/edit_metadata
//= require hydra/batch_select
//= require hydra_collections

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
  $(document).on('click', '.alert .close' , function(){
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
