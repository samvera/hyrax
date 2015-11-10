//= require jquery-ui-1.9.2/jquery.ui.core
//= require jquery-ui-1.9.2/jquery.ui.widget
//= require jquery-ui-1.9.2/jquery.ui.menu
//= require jquery-ui-1.9.2/jquery.ui.autocomplete
//= require jquery-ui-1.9.2/jquery.ui.position
//= require jquery-ui-1.9.2/jquery.ui.effect
//= require jquery-ui-1.9.2/jquery.ui.effect-highlight

//= require bootstrap/dropdown
//= require bootstrap/button
//= require bootstrap/modal
//= require bootstrap/collapse
//= require bootstrap/tooltip
//= require bootstrap/popover
//= require bootstrap/tab

//= require video
//= require audio.min
//= require jquery.validate
//= require swfobject
//= require ZeroClipboard.min
//= require select2

//= require flot/excanvas
//= require flot/jquery.flot
//= require flot/jquery.flot.time
//= require flot/jquery.flot.selection

//= require batch_edit
//= require terms_of_service
//
//= require sufia/app
//= require sufia/fileupload
//= require sufia/permissions
//= require sufia/trophy
//= require sufia/featured_works
//= require sufia/featured_researcher
//= require sufia/batch_select_all
//= require sufia/edit_metadata
//= require sufia/single_use_link
//= require sufia/audio
//= require sufia/search
//= require sufia/editor
//= require sufia/ga_events
//= require sufia/tabs
//= require sufia/user_search
//= require sufia/transfers
//= require sufia/proxy_rights
//= require hydra/batch_select
//= require sufia/dashboard_actions
//= require sufia/batch

//= require hydra_collections
//= require hydra-editor/hydra-editor

//
// For Browse-everything until https://github.com/projecthydra-labs/browse-everything/issues/85 is resolved:
//= require jquery.treetable
//= require browse_everything/behavior
//
//= require jquery.blacklightTagCloud
//= require sufia/tagcloud
//= require nestable

// this needs to be after batch_select so that the form ids get setup correctly
//= require sufia/batch_edit

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

Blacklight.onLoad(function() {

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

  $("a[rel=popover]").click(function() { return false;});

  /*
   * facets lists
   */
  $("li.expandable").click(function(){
    $(this).next("ul").slideToggle();
    $(this).find('i').toggleClass("glyphicon-chevron-right glyphicon-chevron-down");
  });

  $("li.expandable_new").click(function(){
    $(this).find('i').toggleClass("glyphicon-chevron-right glyphicon-chevron-down");
  });

  $(".sorts-dash").click(function(){
    var itag =$(this).find('i');
    toggle_icon(itag);
    sort = itag.attr('class') == "caret" ? itag.attr('id')+' desc' :  itag.attr('id') +' asc';
    $('#sort').val(sort).selected = true;
    $("#dashboard_sort_submit").click();
  });

  $(".sorts").click(function(){
    var itag =$(this).find('i');
    toggle_icon(itag);
    sort = itag.attr('class') == "caret up" ? itag.attr('id')+' desc':  itag.attr('id');
    $('input[name="sort"]').attr('value', sort);
    $("#user_submit").click();
  });

}); //closing function at the top of the page

/*
 * begin functions
 */

function toggle_icon(itag){
       itag.toggleClass("caret");
       itag.toggleClass("caret up");
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
