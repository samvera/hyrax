Blacklight.onLoad(function() {
  $('#show_addl_descriptions').click(function() {
    $('#more_descriptions').show();
    $('#show_addl_descriptions').hide();
    return false;
  });
  $('#hide_addl_descriptions').click(function() {
    $('#more_descriptions').hide();
    $('#show_addl_descriptions').show();
    return false;
  });
  $('#more_descriptions').hide();
});(function( $ ){
  $.fn.singleUseLinks = function( options ) {

    var clipboard = new Clipboard('.copy-single-use-link');

    var manager = {
      reload_table: function() {
        var url = $("table.single-use-links tbody").data('url')
        $.get(url).done(function(data) {
          $('table.single-use-links tbody').html(data);
        });
      },

      create_link: function(caller) {
        $.post(caller.attr('href')).done(function(data) {
          manager.reload_table()
        })
      },

      delete_link: function(caller) {
        $.ajax({
          url: caller.attr('href'),
          type: 'DELETE',
          done: caller.parent('td').parent('tr').remove()
        })
      }
    };

    $('.generate-single-use-link').click(function(event) {
      event.preventDefault()
      manager.create_link($(this))
      return false
    });

    $("table.single-use-links tbody").on('click', '.delete-single-use-link', function(event) {
      event.preventDefault()
      manager.delete_link($(this))
      return false;
    });

    clipboard.on('success', function(e) {
      $(e.trigger).tooltip('show');
      e.clearSelection();
    }); 

    return manager;

  };
})( jQuery );

Blacklight.onLoad(function () {
  $('.single-use-links').singleUseLinks();
});
//= require hyrax/uploader
// This file is the default initialization of the fileupload.  If you want to call
// hyraxUploader with other options (like afterSubmit), then override this file.
Blacklight.onLoad(function() {
  var options = {};
  $('#fileupload').hyraxUploader(options);
  $('#fileuploadlogo').hyraxUploader({downloadTemplateId: 'logo-template-download'});
});
//= require fileupload/tmpl
//= require fileupload/jquery.iframe-transport
//= require fileupload/jquery.fileupload.js
//= require fileupload/jquery.fileupload-process.js
//= require fileupload/jquery.fileupload-validate.js
//= require fileupload/jquery.fileupload-ui.js
//
/*
 * jQuery File Upload Plugin JS Example
 * https://github.com/blueimp/jQuery-File-Upload
 *
 * Copyright 2010, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/MIT
 */

(function( $ ){
  'use strict';

  $.fn.extend({
    hyraxUploader: function( options ) {
      // Initialize our jQuery File Upload widget.
      this.fileupload($.extend({
        // xhrFields: {withCredentials: true},              // to send cross-domain cookies
        // acceptFileTypes: /(\.|\/)(png|mov|jpe?g|pdf)$/i, // not a strong check, just a regex on the filename
        // limitMultiFileUploadSize: 500000000, // bytes
        autoUpload: true,
        url: '/uploads/',
        type: 'POST',
        dropZone: $(this).find('.dropzone')
      }, Hyrax.config.uploader, options))
      .bind('fileuploadadded', function (e, data) {
        $(e.currentTarget).find('button.cancel').removeClass('hidden');
      });

      $(document).bind('dragover', function(e) {
        var dropZone = $('.dropzone'),
            timeout = window.dropZoneTimeout;
        if (!timeout) {
            dropZone.addClass('in');
        } else {
            clearTimeout(timeout);
        }
        var found = false,
            node = e.target;
        do {
            if (node === dropZone[0]) {
                found = true;
                break;
            }
            node = node.parentNode;
        } while (node !== null);
        if (found) {
            dropZone.addClass('hover');
        } else {
            dropZone.removeClass('hover');
        }
        window.dropZoneTimeout = setTimeout(function () {
            window.dropZoneTimeout = null;
            dropZone.removeClass('in hover');
        }, 100);
      });
    }
  });
})(jQuery);
Blacklight.onLoad(function() {
  function toggle_icon(itag){
	 itag.toggleClass("caret");
	 itag.toggleClass("caret up");
  }

  $(".sorts").click(function(){
    var itag =$(this).find('i');
    toggle_icon(itag);
    sort = itag.attr('class') == "caret" ? itag.attr('id') + ' desc' :  itag.attr('id');
    // There is more than one input named sort on the page, so qualifiy with the form class:
    $('.form-search input[name="sort"]').attr('value', sort);
    $("#user_submit").click();
  });
}); //end of Blacklight.onload
// Fixes a problem with csrf tokens and turbolinks
// See https://github.com/rails/jquery-ujs/issues/456
$(document).on('turbolinks:load', function() {
  $.rails.refreshCSRFTokens();
  // Explicitly set flag to false to force loading of UV
  // See https://github.com/samvera/hyrax/issues/2906
  window.embedScriptIncluded = false;
});
Blacklight.onLoad(function() {
  // toggle button on or off based on boxes being clicked
  $(".batch_document_selector, .batch_document_selector_all").bind('click', function(e) {
    var n = $(".batch_document_selector:checked").length;
    if (n>0 || ($('input#check_all').length && $('input#check_all')[0].checked)) {
      $('.sort-toggle').hide();
    } else {
      $('.sort-toggle').show();
    }
  });

  function show_details(item) {
    var array = item.id.split("expand_");
    if (array.length > 1) {
      var docId = array[1];
      $("#detail_" + docId + " .expanded-details").slideToggle();
      $(item).toggleClass('glyphicon-chevron-right glyphicon-chevron-down');
    }
  }

  // show/hide more information on the dashboard when clicking
  // plus/minus
  $('.glyphicon-chevron-right').on('click', function() {
    show_details(this);
    return false;
  });

  $('a').filter( function() {
      return $(this).find('.glyphicon-chevron-right').length === 1;
   }).on('click', function() {
    show_details($(this).find(".glyphicon-chevron-right")[0]);
    return false;
  });

});
(function( $ ){

  $.fn.userSearch = function() {
    return this.each(function() {
      $(this).select2( {
        placeholder: $(this).attr("value") || "Search for a user",
        minimumInputLength: 2,
        id: function(object) {
          return object.user_key;
        },
        initSelection: function(element, callback) {
          var data = {
            id: element.val(),
            text: element.val()
          };
          callback(data);
        },
        ajax: { // Use the jQuery.ajax wrapper provided by Select2
          url: "/users.json",
          dataType: "json",
          data: function (term, page) {
            return {
              uq: term // Search term
            };
          },
          results: function(data, page) {
            return { results: data.users };
          }
        },
      }).select2('data', null);
    });

  };
})( jQuery );
Blacklight.onLoad(function () {
    Hyrax.initialize();
});
// To enable nav safety on a form:
// - Render the shared/nav-safety partial on the page.
// - Add the nav-safety-confirm class to the tab anchor element.
// - Add the nav-safety class to the form element.

Blacklight.onLoad(function() {
  var clickedTab;
  $('.nav-safety-confirm').on('click', function(evt) {
    clickedTab = $(this).attr('href');
    var dirtyData = $('#nav-safety-modal[dirtyData=true]');
    if (dirtyData.length > 0) {
      evt.preventDefault();
      evt.stopPropagation();
      $('#nav-safety-modal').modal('show');
    }
  });
  
  $('#nav-safety-dismiss').on('click', function(evt) {
    nav_safety_off();
    // Navigate away from active tab to clicked tab
    window.location = clickedTab;
  });
  
  $('form.nav-safety').on('change', function(evt) {
    nav_safety_on();
  });
  $('form.nav-safety').on('reset', function(evt) {
    nav_safety_off();
  });
});

function nav_safety_on() {
  $('#nav-safety-modal')[0].setAttribute('dirtyData', true);
}

function nav_safety_off() {
  $('#nav-safety-modal')[0].setAttribute('dirtyData', false);
}

function tinymce_nav_safety(editor) {editor.on('Change', function (e) {
  $(e.target.targetElm).parents('form.nav-safety').change();
});
}
// This code is to implement the tabs on the home page

// navigate to the selected tab or the first tab
function tabNavigation(e) {
    var activeTab = $('[href="' + location.hash + '"]');
    if (activeTab.length) {
        activeTab.tab('show');
    } else {
        var firstTab = $('.nav-tabs a:first');
        // select the first tab if it has an id and is expected to be selected
        if ((firstTab[0] !== undefined) && (firstTab[0].id != "")){
          $(firstTab).tab('show');
        }
    }
}

Blacklight.onLoad(function () {
  // When we visit a link to a tab, open that tab.
  var url = document.location.toString();
  if (url.match('#')) {
    $('.nav-tabs a[href="#' + url.split('#')[1] + '"]').tab('show');
  }

  // Change the url when a tab is clicked.
  $('a[data-toggle="tab"]').on('click', function(e) {
    // Set turbolinks: true so that turbolinks can handle the back requests
    // See https://github.com/turbolinks/turbolinks/blob/master/src/turbolinks/history.coffee#L28
    history.pushState({turbolinks: true}, null, $(this).attr('href'));
  });
  // navigate to a tab when the history changes (back button)
  window.addEventListener("popstate", tabNavigation);
});
function setWeight(node, weight) {
  weightField(node).val(weight);
}

/* find the input element with data-property="order" that is nested under the given node */
function weightField(node) {
  return findProperty(node, "order");
}

function findProperty(node, property) {
  return node.find("input[data-property=" + property + "]");
}

function findNode(id, container) {
  return container.find("[data-id="+id+"]");
}

function dragAndDrop(selector) {
  selector.nestable({maxDepth: 1});
  selector.on('change', function(event) {
    // Scope to a container because we may have two orderable sections on the page
    container = $(event.currentTarget);
    var data = $(this).nestable('serialize')
    var weight = 0;
    for(var i in data){
      var parent_id = data[i]['id'];
      parent_node = findNode(parent_id, container);
      setWeight(parent_node, weight++);
    }
  });
}

Blacklight.onLoad(function() {
  $('a[data-behavior="feature"]').on('click', function(evt) {
    evt.preventDefault();
    anchor = $(this);
    $.ajax({
       url: anchor.attr('href'),
       type: "post",
       success: function(data) {
         anchor.addClass('collapse');
         $('a[data-behavior="unfeature"]').removeClass('collapse')

       }
    });
  });

  $('a[data-behavior="unfeature"]').on('click', function(evt) {
    evt.preventDefault();
    anchor = $(this);
    $.ajax({
       url: anchor.attr('href'),
       type: "post",
       data: {"_method":"delete"},
       success: function(data) {
         anchor.addClass('collapse');
         $('a[data-behavior="feature"]').removeClass('collapse')
       }
    });
  });

  dragAndDrop($('#dd'));
});
function toggleTrophy(url, anchor) {
  $.ajax({
     url: url,
     type: "post",
     success: function(data) {
       gid = data.work_id;
       if (anchor.hasClass("trophy-on")){
         // we've just removed the trophy
         trophyOff(anchor);
       } else {
         trophyOn(anchor);
       }

       anchor.toggleClass("trophy-on");
       anchor.toggleClass("trophy-off");
     }
  });
}
// Trophy will be removed from the public profile page
function trophyOff(anchor) {
    if (anchor.data('removerow')) {
        $('#trophyrow_'+gid).fadeOut(1000, function() {
            $('#trophyrow_'+gid).remove();
        });
    } else {
        setAnchorAttrs(anchor, 'Highlight work', 'add-text');
    }
}

function trophyOn(anchor) {
    setAnchorAttrs(anchor, 'Unhighlight work', 'remove-text');
}

function setAnchorAttrs(anchor, title, data) {
    anchor.attr('title', title);
    $nodes = anchor.contents();
    $nodes[$nodes.length - 1].nodeValue = anchor.data(data)
}

Blacklight.onLoad( function() {
  // #this method depends on a "current_user" global variable having been set.
  $('.trophy-class').click(function(evt){
    evt.preventDefault();
    anchor = $(this);
    toggleTrophy(anchor.data('url'), anchor);
  });
});
//= require jquery.treetable
//= require browse_everything/behavior

// Show the files in the queue
Blacklight.onLoad( function() {
  // We need to check this because https://github.com/samvera/browse-everything/issues/169
  if ($('#browse-btn').length > 0) {
    $('#browse-btn').browseEverything()
    .done(function(data) {
      var evt = { isDefaultPrevented: function() { return false; } };
      var files = $.map(data, function(d) { return { name: d.file_name, size: d.file_size, id: d.url } });
      $.blueimp.fileupload.prototype.options.done.call($('#fileupload').fileupload(), evt, { result: { files: files }});
    })
  }
});
(function( $ ){

  $.fn.proxyRights = function( options ) {

    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    var $container = this;

    function addContributor(name, user_key, grantor) {
      data = {name: name, user_key: user_key}

      $.ajax({
        type: "POST",
        url: '/users/'+grantor+'/depositors',
        dataType: 'json',
        data: {grantee_id: user_key},
        success: function (data) {
          if (data.name !== undefined) {
            row = rowTemplate(data);
            $('#authorizedProxies tbody', $container).append(row);
            if (settings.afterAdd)
              settings.afterAdd(this, cloneElem);
          }
        },
        error: function (data) {
          if (data.responseJSON !== undefined) {
            errorMsg = data.responseJSON.description;
            $('#errorMsg').text(errorMsg);
            $('#proxy-deny-modal').modal('show');
            return;
          }
        }
      })
      return false;
    }

    function removeContributor(event) {
      event.preventDefault();
      $.ajax({
        url: $(this).closest('a').prop('href'),
        type: "post",
        dataType: "json",
        data: {"_method":"delete"}
      });
      $(this).closest('tr').remove();
      return false;
    }

    function rowTemplate (data) {
      return '<tr>'+
                '<td class="depositor-name">'+data.name+'</td>'+
                '<td><a class="remove-proxy-button btn btn-danger" data-method="delete" href="'+data.delete_path+'" rel="nofollow">'+
                $('#delete_button_label').data('label')+'</a>'+
                '</td>'+
              '</tr>'
    }

    $("#user").userSearch();
    $("#user").on("change", function() {
      // Remove the choice from the select2 widget and put it in the table.
      obj = $("#user").select2("data")
      grantor = $('#user').data('grantor')
      $("#user").select2("val", '')
      addContributor(obj.text, obj.user_key, grantor);
    });

    $('body').on('click', 'a.remove-proxy-button', removeContributor);

  };

})( jQuery );

Blacklight.onLoad(function() {
  $('.proxy-rights').proxyRights();
});
Blacklight.onLoad(function() {
  // hide the editor initially
  $('[data-behavior="reveal-editor"]').each(function(){$($(this).data('target')).hide();});

  // Show the form, hide the preview
  $('[data-behavior="reveal-editor"]').on('click', function(evt) {
    evt.preventDefault();
    $this = $(this);
    $this.parent().hide();
    $($this.data('target')).show();
  });
});
// Callbacks for tracking events using Google Analytics

// Note: there is absence of testing here.  I'm not sure how or to what extent we can test what's getting
// sent to Google Analytics.

$(document).on('click', '#file_download', function(e) {
  _gaq.push(['_trackEvent', 'Files', 'Downloaded', $(this).data('label')]);
    
});

//= require hyrax/relationships/control
//= require hyrax/relationships/registry
//= require hyrax/relationships/registry_entry
//= require hyrax/relationships/confirm_remove_dialog
//= require hyrax/relationships/resource
function batch_edit_init () {

    function deserialize(Params) {
        var Data = Params.split("&");
        var i = Data.length;
        var Result  = {};
        while (i--) {
            var Pair = decodeURIComponent(Data[i]).split("=");
            var key = Pair[0];
            var val = Pair[1];
            if (Result[key] != null) {
                if(!$.isArray(Result[key])) Result[key] = [Result[key]];
                Result[key].push(val);
            } else
                Result[key] = val;
        }
        return Result;
    }

    var ajaxManager = (function () {
        var requests = [];
        var running = false;
        return {
            addReq: function (opt) {
                requests.push(opt);
            },
            removeReq: function (opt) {
                if ($.inArray(opt, requests) > -1)
                    requests.splice($.inArray(opt, requests), 1);
            },
            runNow: function () {
                clearTimeout(this.tid);
                if (!running) {
                    this.run();
                }
            },
            run: function () {
                running = true;
                var self = this;

                if (requests.length) {

                    // combine data from multiple requests
                    if (requests.length > 1) {
                      requests = this.combine_requests(requests);
                    }

                    requests = this.setup_request_complete(requests);
                    $.ajax(requests[0]);
                } else {
                    self.tid = setTimeout(function () {
                        self.run.apply(self, []);
                    }, 500);
                    running = false;
                }
            },
            stop: function () {
                requests = [];
                clearTimeout(this.tid);
            },
            setup_request_complete: function (requests) {
                oriComp = requests[0].complete;

                requests[0].complete = [ function (e) {
                    req = requests.shift();
                    if (typeof req.form === 'object') {
                        for (f in req.form) {
                            form_id = form[f];
                            after_ajax(new BatchEditField($("#"+form_id)));
                        }
                    }
                    this.tid = setTimeout(function () {
                        ajaxManager.run.apply(ajaxManager, []);
                    }, 50);
                    return true;
                }];
                if (typeof oriComp === 'function') requests[0].complete.push(oriComp);
                return requests;
            },
            combine_requests: function (requests) {
                var data = deserialize(requests[0].data.replace(/\+/g, " "));
                var adata;
                form = [requests[0].form]
                for (var i = requests.length - 1; i > 0; i--) {
                    req = requests.pop();
                    adata = deserialize(req.data.replace(/\+/g, " "));

                    for (key in  Object.keys(adata)) {
                        curKey = Object.keys(adata)[key];
                        if (curKey.slice(0, 12) == req.key) {
                            data[curKey] = adata[curKey];
                            form.push(req.form);
                        }
                    }
                }
                requests[0].data = $.param(data);
                requests[0].form = form;
                return requests;
            }
        };
    }());

    ajaxManager.run();

    function after_ajax(form) {
        form.enableForm();
    }

    function before_ajax(form) {
        form.disableForm();
    }

    var BatchEditField = function (form) {
        this.form = form;
        this.formButtons = form.find('.btn');
        this.formFields = form.find('.form-group > *');
        this.formRightPanel = form.find('.form-group');
        this.statusField = form.find('.status');
    }

    BatchEditField.prototype = {
        disableForm: function () {
            this.formButtons.attr("disabled", "disabled");
            this.formRightPanel.addClass("loading");
            this.formFields.addClass('invisible')
        },

        enableForm: function () {
            this.statusField.html("Changes Saved");
            this.formButtons.removeAttr("disabled");
            this.formRightPanel.removeClass("loading");
            this.formFields.removeClass('invisible')
        }
    }

    function runSave(e) {
        e.preventDefault();
        var button = $(this);
        var form = button.closest('form');
        var f = new BatchEditField(form);
        var form_id = form[0].id;
        before_ajax(f);

        ajaxManager.addReq({
            form: form_id,
            key: form.data('model'),
            queue: "add_doc",
            url: form.attr("action"),
            dataType: "json",
            type: form.attr("method").toUpperCase(),
            data: form.serialize(),
            success: function (e) {
                after_ajax(f);
            },
            fail: function (e) {
                alert("Error!  Status: " + e.status);
            }
        });
        setTimeout(ajaxManager.runNow(), 100);
    }

    $("#permissions_visibility_save").click(runSave);
    $("#permissions_roles_save").click(runSave);
    $(".field-save").click(runSave);
}

Blacklight.onLoad(function() {
  // set up global batch edit options to override the ones in the hydra-batch-edit gem
  window.batch_edits_options = { checked_label: "",
                                 unchecked_label: "",
                                 progress_label: "",
                                 status_label: "",
                                 css_class: "batch_toggle" };
  batch_edit_init();

}); //end of Blacklight.onload
Blacklight.onLoad(function() {
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

}); //end of Blacklight.onload
var autocompleteModule = require('hyrax/autocomplete');

Blacklight.onLoad(function () {

  /**
   * Post modal data via Ajax to avoid nesting <forms> in edit collections tabs screen
   * @param  {string} url   URL where to submit the AJAX request
   * @param  {string} type  The type of network request: 'POST', 'DELETE', etc.
   * @param  {object} data  Data object to send with network request.  Should default to {}
   * @param  {jQuery object} $self Reference to the jQuery context ie. $(this) of calling statemnt
   * @return {void}
   */
  function submitModalAjax(url, type, data, $self) {
    $.ajax({
      type: type,
      url: url,
      data: data
    }).done(function(response) {
    }).fail(function(err) {
      var alertNode = buildModalErrorAlert(err);
      var $alert = $self.closest('.modal').find('.modal-ajax-alert');
      $alert.html(alertNode);
    });
  }

  /**
   * HTML for ajax error alert message, in case the AJAX request fails
   * @param  {object} err AJAX response object
   * @return {string}     The constructed HTML alert string
   */
  function buildModalErrorAlert(err) {
    var message = (err.responseText ? err.responseText : 'An unknown error has occurred');
    var elHtml = '<div class="alert alert-danger alert-dismissible" role="alert"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><span class="message">' + message + '</span></div>';
    return elHtml;
  }

  /**
   * Handle delete collection submit button click from within a generic modal
   * @return {void}
   */
  function handleModalDeleteCollection() {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postDeleteUrl'),
      data = {};
    if (url.length === 0) {
      return;
    }
    $self.prop('disabled', true);
    submitModalAjax(url, 'DELETE', data, $self);
  }

  /**
   * Sync collection data attributes to the singular instance of the modal so it knows what data to post
   * @param {string} modalId - The id of modal to target, ie. #add_collection_modal
   * @param {[string]} dataAttributes - An string array of "data-xyz" data attributes WITHOUT
   * the "data-" prefix. ie. ['id', 'some-var']
   * @param {jquery Object} $dataEl - jQuery object reference which has values of data attributes we're copying over
   * @return {void}
   */
  function addDataAttributesToModal(modalId, dataAttributes, $dataEl) {
    // Remove and add new data attributes
    dataAttributes.forEach(function(attribute) {
      $(modalId).removeAttr('data-' + attribute).attr('data-' + attribute, $dataEl.data(attribute));
    });
  }

  /**
   * Build <option>s markup for add collection to collection
   * @param  {[objects]} collsHash An array of objects representing a needed data from Collection(s)
   * @return {string} <options> string markup which will populate the <select> element
   */
  function buildSelectMarkup(collsHash) {
    var options = collsHash.map(function(col) {
      return '<option value="' + col.id + '">' + col.title_first + '</option>';
    });
    var markup = options.join('');
    return markup;
  }

  /**
   * Handle "add to collection" element click event.
   * @param  {Mouseevent} e
   * @return {void}
   */
  function handleAddToCollection(e) {
    e.preventDefault();
    var $self = $(this),
      $dataEl = (
        $self.closest('#collections-list-table').length > 0 ?
        $self.closest('tr') :
        $self.closest('section')
      ),
      selectMarkup = '',
      $firstOption = null;

    // Show deny modal
    if ($self.data('nestable') === false) {
      $('#add-to-collection-deny-modal').modal('show');
      return;
    }
    // Show modal permission denied
    if ($self.data('hasaccess') === false) {
      $('#add-to-collection-permission-deny-modal').modal('show');
      return;
    }
    // Show add to collection modal below
    addDataAttributesToModal('#add-to-collection-modal', ['id', 'post-url'], $dataEl);
    // Grab reference to the default <option> in modal
    $firstOption = $('#add-to-collection-modal').find('select[name="parent_id"] option');
    // Remove all previous <options>s
    $firstOption.not(':first').remove();
    // Build new <option>s markup and put on DOM
    selectMarkup = buildSelectMarkup($dataEl.data('collsHash'));
    $(selectMarkup).insertAfter($firstOption);

    // Disable the submit button in modal by default
    $('#add-to-collection-modal').find('.modal-submit-button').prop('disabled', true);

    // Show modal
    $('#add-to-collection-modal').modal('show');
  }

  /**
   * Handle "delete collection" button click event
   * @param  {Mouseevent} e
   * @return {void}
   */
  function handleDeleteCollection(e) {
    e.preventDefault();
    var $self = $(this),
      $tr = $self.parents('tr'),
      totalitems = $self.data('totalitems'),
      // membership set to true indicates admin_set
      membership = $self.data('membership') === true,
      collectionId = $tr.data('id'),
      modalId = '';

    // Permissions denial
    if ($(this).data('hasaccess') !== true) {
      $('#collection-to-delete-deny-modal').modal('show');
      return;
    }
    // Admin set with child items
    if (totalitems > 0 && membership) {
      $('#collection-admin-set-delete-deny-modal').modal('show');
      return;
    }
    modalId = (totalitems > 0 ?
      '#collection-to-delete-modal' :
      '#collection-empty-to-delete-modal'
    );
    addDataAttributesToModal(modalId, ['id', 'post-delete-url'], $tr);
    $(modalId).modal('show');
  }

  /**
   * Generically disable modal submit buttons unless their select element
   * has a valid value.
   *
   * To Use:
   * 1.) Put the '.disable-unless-selected' class on the '.modal' element you wish to protect.
   * 2.) Add the 'disabled' attribute to your protected submit button ie. <button disabled ...>.
   * 3.) Put the '.modal-submit-button' class on whichever button you wish to disable for an invalid
   * <select> value ie. <button disabled class="... modal-submit-button" ...>
   *
   * @return {void}
   */
  $('.modal.disable-unless-selected select').on('change', function() {
    var selectValue = $(this).val(),
      emptyValues = ['', 'none'],
      selectHasAValue = emptyValues.indexOf(selectValue) === -1,
      $submitButton = $(this).parents('.modal').find('.modal-submit-button');

    $submitButton.prop('disabled', !selectHasAValue);
  });

  // Add click listeners for collections buttons which initiate modal action windows
  $('.add-to-collection').on('click', handleAddToCollection);
  $('.delete-collection-button').on('click', handleDeleteCollection);

  // change the action based which collection is selected
  // This expects the form to have a path that includes the string 'collection_replace_id'
  $('[data-behavior="updates-collection"]').on('click', function() {
      var string_to_replace = "collection_replace_id",
        form = $(this).closest("form"),
        collection_id = $('#member_of_collection_ids')[0].value;

      form[0].action = form[0].action.replace(string_to_replace, collection_id);
      form.append('<input type="hidden" value="add" name="collection[members]"></input>');
  });

  // Initializes the autocomplete element for the add to collection modal
  $('#collection-list-container').on('show.bs.modal', function() {
    var inputField = $('#member_of_collection_ids');
    var autocomplete = new autocompleteModule();
    autocomplete.setup(inputField, inputField.data('autocomplete'), inputField.data('autocompleteUrl'));
  });

  // Display access deny for edit request.
  $('#documents').find('.edit-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#collections-to-edit-deny-modal').modal('show');
  });

  // Display access deny for remove parent collection button.
  $('#parent-collections-wrapper').find('.remove-parent-from-collection-deny-button').on('click', function (e) {
    e.preventDefault();
    $('#parent-collection-to-remove-deny-modal').modal('show');
  });

  // Remove this parent collection list button clicked
  $('#parent-collections-wrapper')
    .find('.remove-from-collection-button')
    .on('click', function (e) {
    var $dataEl = $(this).closest('li'),
      modalId = '#collection-remove-from-collection-modal';

    addDataAttributesToModal(modalId, ['id', 'parent-id', 'post-url'], $dataEl);
    $(modalId).modal('show');
  });

  // Remove this sub-collection list button clicked
  $('#sub-collections-wrapper')
    .find('.remove-subcollection-button')
    .on('click', function (e) {
    var $dataEl = $(this).closest('li'),
      modalId = '#collection-remove-subcollection-modal';

    addDataAttributesToModal(modalId, ['id', 'parent-id', 'post-url'], $dataEl);
    $(modalId).modal('show');
  });

  // Remove collection from list modal "Submit/Remove" button clicked
  $('.modal-button-remove-collection').on('click', function(e) {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postUrl'),
      data = {};
    if (url.length === 0) {
      return;
    }
    $self.prop('disabled', true);
    submitModalAjax(url, 'POST', data, $self);
  });

  // Delete selected collections button click
  $('#delete-collections-button').on('click', function () {
    var tableRows = $('#documents table.collections-list-table tbody tr');
    var checkbox = null;
    var numRowsSelected = false;
    var $modal = $('#selected-collections-delete-modal');
    var $deleteWordingTarget = $modal.find('.pluralized');
    var deleteWording = {
      plural: $modal.data("pluralForm"),
      singular: $modal.data("singularForm")
    };

    var canDeleteAll = true;
    var selectedInputs = $('#documents table.collections-list-table tbody tr')
      // Get all inputs in the table
      .find('td:first input[type=checkbox]')
      // Filter to those that are checked
      .filter(function(i, checkbox) { return checkbox.checked; });

    var cannotDeleteInputs = selectedInputs.filter(function(i, checkbox) { return checkbox.dataset.hasaccess === "false"; });
    if(cannotDeleteInputs.length > 0) {
      // TODO: Can we pass data to this modal to be more specific about which ones they cannot delete?
      $('#collections-to-delete-deny-modal').modal('show');
      return;
    }

    if (selectedInputs.length > 0) {
      // Collections are selected
      // Update singular / plural text in delete modal
      if (selectedInputs.length > 1) {
        $deleteWordingTarget.text(deleteWording.plural);
      } else {
        $deleteWordingTarget.text(deleteWording.singular);
      }
      $modal.modal('show');
    }
  });

  // Add to collection modal form post
  $('#add-to-collection-modal').find('.modal-add-button').on('click', function (e) {
    var $self = $(this),
      $modal = $self.closest('.modal'),
      url = $modal.data('postUrl'),
      parentId = $modal.find('[name="parent_id"]').val(),
      data = {
        parent_id: parentId,
        // source parameter is used by NestCollectionsController#redirect_path
        source: $self.data('source')
      };
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, 'POST', data, $self);
  });

  // Handle delete collection modal submit button click event
  ['#collection-to-delete-modal', '#collection-empty-to-delete-modal'].forEach(function(id) {
    $(id).find('.modal-delete-button').on('click', handleModalDeleteCollection);
  });

  // Add sub collection to collection form post
  $('[id^="add-subcollection-modal-"]').find('.modal-add-button').on('click', function (e) {
    var url = $(this).data('postUrl'),
      childId = $(this).closest('.modal').find('[name="child_id"]').val(),
      data = {
      child_id: childId,
      // source parameter is used by NestCollectionsController#redirect_path
      source: $(this).data('source')
    };
    if (url.length === 0) {
      return;
    }
    submitModalAjax(url, 'POST', data, $(this));
  });


  // Handle add a subcollection button click on the collections show page
  $('.sub-collections-wrapper button.add-subcollection').on('click', function (e) {
    $('#add-subcollection-modal-' + $(this).data('presenterId')).modal('show');
  });

});
$(function() {
  if (typeof hyrax_item_stats === "undefined") {
    return;
  }

  function weekendAreas(axes) {
    var markings = [],
      d = new Date(axes.xaxis.min);

    // go to the first Saturday
    d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 1) % 7))
    d.setUTCSeconds(0);
    d.setUTCMinutes(0);
    d.setUTCHours(0);

    var i = d.getTime();

    // when we don't set yaxis, the rectangle automatically
    // extends to infinity upwards and downwards

    do {
      markings.push({ xaxis: { from: i, to: i + 2 * 24 * 60 * 60 * 1000 } });
      i += 7 * 24 * 60 * 60 * 1000;
    } while (i < axes.xaxis.max);

    return markings;
  }

  var options = {
    xaxis: {
      mode: "time",
      tickLength: 5
    },
    yaxis: {
      tickDecimals: 0,
      min: 0
    },
    series: {
      lines: {
        show: true,
        fill: true
      },
      points: {
        show: true,
        fill: true
      }
    },
    selection: {
      mode: "x"
    },
    grid: {
      hoverable: true,
      clickable: true,
      markings: weekendAreas
    }
  };

  var plot = $.plot("#usage-stats", hyrax_item_stats, options);

  $("<div id='tooltip'></div>").css({
    position: "absolute",
    display: "none",
    border: "1px solid #bce8f1",
    padding: "2px",
    "background-color": "#d9edf7",
    opacity: 0.80
  }).appendTo("body");

  $("#usage-stats").bind("plothover", function (event, pos, item) {
    if (item) {
      date = new Date(item.datapoint[0]);
      months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]
      $("#tooltip").html("<strong>" + item.series.label + ": " + item.datapoint[1] + "</strong><br/>" + months[date.getMonth()] + " " + date.getDate() + ", " + date.getFullYear())
            .css({top: item.pageY+5, left: item.pageX+5})
            .fadeIn(200);
    } else {
      $("#tooltip").fadeOut(100)
    }
  });

  var overview = $.plot("#overview", hyrax_item_stats, {
    series: {
      lines: {
        show: true,
        lineWidth: 1
      },
      shadowSize: 0
    },
    xaxis: {
      ticks: [],
      mode: "time",
      minTickSize: [1, "day"]
    },
    yaxis: {
      ticks: [],
      min: 0,
      autoscaleMargin: 0.1
    },
    selection: {
      mode: "x"
    },
    legend: {
      show: false
    }
  });

  $("#usage-stats").bind("plotselected", function(event, ranges) {
    plot = $.plot("#usage-stats", hyrax_item_stats, $.extend(true, {}, options, {
      xaxis: {
        min: ranges.xaxis.from,
        max: ranges.xaxis.to
      }
    }));
    overview.setSelection(ranges, true);
  });

  $("#overview").bind("plotselected", function(event, ranges) {
    plot.setSelection(ranges);
  });
});

  // function to hide or show the batch update buttons based on how may items are checked
  function toggleButtons(forceOn, otherPage ){
    forceOn = typeof forceOn !== 'undefined' ? forceOn : false
    otherPage = typeof otherPage !== 'undefined' ? otherPage : !window.batch_part_on_other_page;
    var n = $(".batch_document_selector:checked").length;
    if ((n>0) || (forceOn)) {
        $('.batch-toggle').show();
        $('.batch-select-all').removeClass('hidden');
        $('#batch-edit').removeClass('hidden');
    } else if ( otherPage){
        $('.batch-toggle').hide();
        $('.batch-select-all').addClass('hidden');
        $('#batch-edit').addClass('hidden');
    }
    $("body").css("cursor", "auto");
  }


  // change the state of a cog menu item and add or remove the check beside it
  // using on or off instead of true or false
  function toggleState (obj, state) {
    toggleStateBool(obj, state == 'on');
  }

  // change the state of a cog menu item and add or remove the check beside it
  function toggleStateBool (obj, state) {
    if (state){
      obj.attr("data-state", 'on');
      obj.find('a i').addClass('glyphicon glyphicon-ok');
    }else {
      obj.attr("data-state", 'off');
      obj.find('a i').removeClass('glyphicon glyphicon-ok');
    }

  }


  // check all the check boxes on the page
  function check_all_page(e) {
    // get the check box state
    var checked = $("#check_all")[0]['checked'];

    // check each individual box
    $("input[type='checkbox'].batch_document_selector").each(function(index, value) {
       value['checked'] = checked;
    });
    toggleButtons();

    // set menu check marks
    toggleStateBool($("[data-behavior='batch-edit-select-page']"),checked);
    toggleStateBool($("[data-behavior='batch-edit-select-none']"),!checked);

  }

  // turn page selection on or off
  // state == true for on
  function select_page ( state) {
    // check everything on the current page on or off based on state
    $("#check_all").prop('checked', state);
    check_all_page();
  }

Blacklight.onLoad(function() {
  // check the select all page cog menu item and select the entire page
  $("[data-behavior='batch-edit-select-page']").bind('click', function(e) {
    e.preventDefault();
    select_page(true);
  });

  // check the select none cog menu item and de-select the entire page
  $("[data-behavior='batch-edit-select-none']").bind('click', function(e) {
    e.preventDefault();
    select_page(false);
  });

  // check all check boxes
  $("#check_all").bind('click', check_all_page);
  
  // select/deselect all check boxes 
  $("#checkAllBox").change(function () {
    $("input:checkbox").prop('checked', $(this).prop("checked"));
  });

  // toggle button on or off based on boxes being clicked
  $(".batch_document_selector").bind('click', function(e) {
     toggleButtons();
  });

  // toggle the state of the select boxes in the cog menu if all buttons are
  $(".batch_document_selector").bind('click', function(e) {

      // count the check boxes currently checked
      var selectedCount = $(".batch_document_selector:checked").length;

      // toggle the cog menu check boxes
      toggleStateBool($("[data-behavior='batch-edit-select-page']"),selectedCount == window.document_list_count);
      toggleStateBool($("[data-behavior='batch-edit-select-none']"),selectedCount == 0);

      // toggle the check all check box
      $("#check_all").attr('checked', (selectedCount == window.document_list_count));

    });

    if ($("#check_all").length > 0) select_page(false);

});
(function($){
  Hyrax.Search = function (element) {
    this.$element = $(element);

    this.init = function() {
      this.$label = this.$element.find('[data-search-element="label"]');
      this.$items = this.$element.find('[data-search-option]');
      this.setDefault();
    }

    this.init();
    this.attachEvents();
  }


  Hyrax.Search.prototype = {
    attachEvents: function() {

      _this = this;
      this.$items.on('click', function(event) {
        event.preventDefault();
        _this.clicked($(this))
      });
    },

    clicked: function($anchor) {
      this.setLabel($anchor.data('search-label'));
      this.setFormAction($anchor.data('search-option'));
    },

    setFormAction: function(path) {
      this.$element.attr('action', path);
    },

    getLabelForValue: function(value) {
      selected = this.$element.find('[data-search-option="'+ value +'"]');
      return selected.data('search-label');
    },

    setDefault: function() {
      this.setLabel(this.getLabelForValue(this.$element.attr('action')));
    },

    setLabel: function(label) {
      this.$label.html(label);
    }

  }

  $.fn.search = function(option) {
    return this.each(function() {
      var $this = $(this);
      var data  = $this.data('search');

      if (!data) $this.data('search', (data = new Hyrax.Search(this)));
    })
  }

})(jQuery);


Blacklight.onLoad(function() {
  $('#search-form-header').search();
});

//= require hyrax/permissions/control
//= require hyrax/permissions/registry
//= require hyrax/permissions/registry_entry
//= require hyrax/permissions/user_controls
//= require hyrax/permissions/group_controls
//= require hyrax/permissions/group
//= require hyrax/permissions/person
//= require hyrax/permissions/grant
//override the blacklight default to submit
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
// Dynamically load the file options into the "Thumbnail" select field.

  /*
   * @param {String} url the search endpoint
   * @param {jQuery} the field to add the select to
   */
  constructor(url, field) {
    this.loadThumbnailOptions(url, field)
  }

  // Dynamically load the file options into the "Thumbnail" select field.
  loadThumbnailOptions(url, field) {
      field.select2({
          ajax: { // Use the jQuery.ajax wrapper provided by Select2
              url: url,
              dataType: "json",
              results: function(data, page) {
                return { results: data }
              }
          },
          initSelection: function(element, callback) {
              // the input tag has a value attribute preloaded that points to a preselected repository's id
              // this function resolves that id attribute to an object that select2 can render
              // using its formatResult renderer - that way the repository name is shown preselected
              callback({ text: $(element).data('text') })
          }
      })
  }
}





  /**
   * Setup for the autocomplete field.
   * @param {jQuery} element - The input field to add autocompete to
   * @param {string} fieldName - The name of the field (e.g. 'based_near')
   * @param {string} url - The url for the autocompete search endpoint
   */
  setup (element, fieldName, url) {
    switch (fieldName) {
      case 'work':
        new Resource(
          element,
          url,
          { excluding: element.data('exclude-work') }
        )
        break
      case 'collection':
        new Resource(
          element,
          url)
        break
      case 'based_near':
        new LinkedData(element, url)
      default:
        new Default(element, url)
        break
    }
  }
}

  /**
   * Initializes the class in the context of an individual table element
   * @param {jQuery} element the table element that this class represents
   */
  constructor(element) {
      this.$element = element;
      this.target = element.data('target')
      this.modal = $(this.target)
      this.form = this.modal.find('form.new-collection-select')

      // launch the modal.
      element.on('click', (e) => {
          e.preventDefault()
          this.form.on('submit', this.routingLogic.bind(this))
      });

      // remove the routing logic when the modal is hidden
      this.modal.on('hide.bs.modal', (e) => {
          this.form.unbind('submit')
      });
  }

  // when the form is submitted route to the correct location
  routingLogic(e) {
      e.preventDefault()
      if (this.destination() === undefined)
        return false
      // get the destination from the data attribute of the selected radio button
      window.location.href = this.destination()
  }

  // Each input has two attributes that contain paths, one for the batch and one
  // for a single work.  So, given the value of 'this.type', return the appropriate
  // path.
  destination() {
      return this.form.find('input[type="radio"]:checked').data("path")
  }
}






/**
 * Polyfill String.prototype.startsWith()
 */
if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(searchString, position){
      position = position || 0;
      return this.substr(position, searchString.length) === searchString;
  };
}


  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the save panel
   * @param {AdminSetWidget} adminSetWidget the control for the adminSet dropdown
   */
  constructor(element, adminSetWidget) {
    if (element.length < 1) {
      return
    }
    this.element = element
    this.adminSetWidget = adminSetWidget
    this.form = element.closest('form')
    element.data('save_work_control', this)
    this.activate();
  }

  /**
   * Keep the form from submitting (if the return key is pressed)
   * unless the form is valid.
   *
   * This seems to occur when focus is on one of the visibility buttons
   */
  preventSubmitUnlessValid() {
    this.form.on('submit', (evt) => {
      if (!this.isValid())
        evt.preventDefault();
    })
  }

  /**
   * Keep the form from being submitted many times.
   *
   */
  preventSubmitIfAlreadyInProgress() {
    this.form.on('submit', (evt) => {
      if (this.isValid())
        this.saveButton.prop("disabled", true);
    })
  }

  /**
   * Keep the form from being submitted while uploads are running
   *
   */
  preventSubmitIfUploading() {
    this.form.on('submit', (evt) => {
      if (this.uploads.inProgress) {
        evt.preventDefault()
      }
    })
  }

  /**
   * Is the form for a new object (vs edit an existing object)
   */
  get isNew() {
    return this.form.attr('id').startsWith('new')
  }

  /*
   * Call this when the form has been rendered
   */
  activate() {
    if (!this.form) {
      return
    }
    this.requiredFields = new RequiredFields(this.form, () => this.formStateChanged())
    this.uploads = new UploadedFiles(this.form, () => this.formStateChanged())
    this.saveButton = this.element.find(':submit')
    this.depositAgreement = new DepositAgreement(this.form, () => this.formStateChanged())
    this.requiredMetadata = new ChecklistItem(this.element.find('#required-metadata'))
    this.requiredFiles = new ChecklistItem(this.element.find('#required-files'))
    this.requiredAgreement = new ChecklistItem(this.element.find('#required-agreement'))
    new VisibilityComponent(this.element.find('.visibility'), this.adminSetWidget)
    this.preventSubmit()
    this.watchMultivaluedFields()
    this.formChanged()
    this.addFileUploadEventListeners();
  }

  addFileUploadEventListeners() {
    let $uploadsEl = this.uploads.element;
    const $cancelBtn = this.uploads.form.find('#file-upload-cancel-btn');

    $uploadsEl.bind('fileuploadstart', () => {
      $cancelBtn.removeClass('hidden');
    });

    $uploadsEl.bind('fileuploadstop', () => {
      $cancelBtn.addClass('hidden');
    });
  }

  preventSubmit() {
    this.preventSubmitUnlessValid()
    this.preventSubmitIfAlreadyInProgress()
    this.preventSubmitIfUploading()
  }

  // If someone adds or removes a field on a multivalue input, fire a formChanged event.
  watchMultivaluedFields() {
      $('.multi_value.form-group', this.form).bind('managed_field:add', () => this.formChanged())
      $('.multi_value.form-group', this.form).bind('managed_field:remove', () => this.formChanged())
  }

  // Called when a file has been uploaded, the deposit agreement is clicked or a form field has had text entered.
  formStateChanged() {
    this.saveButton.prop("disabled", !this.isSaveButtonEnabled);
  }

  // called when a new field has been added to the form.
  formChanged() {
    this.requiredFields.reload();
    this.formStateChanged();
  }

  // Indicates whether the "Save" button should be enabled: a valid form and no uploads in progress
  get isSaveButtonEnabled() {
    return this.isValid() && !this.uploads.inProgress;
  }

  isValid() {
    // avoid short circuit evaluation. The checkboxes should be independent.
    let metadataValid = this.validateMetadata()
    let filesValid = this.validateFiles()
    let agreementValid = this.validateAgreement(filesValid)
    return metadataValid && filesValid && agreementValid
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.check()
      return true
    }
    this.requiredMetadata.uncheck()
    return false
  }

  // sets the files indicator to complete/incomplete
  validateFiles() {
    if (!this.uploads.hasFileRequirement) {
      return true
    }
    if (!this.isNew || this.uploads.hasFiles) {
      this.requiredFiles.check()
      return true
    }
    this.requiredFiles.uncheck()
    return false
  }

  validateAgreement(filesValid) {
    if (filesValid && this.uploads.hasNewFiles && this.depositAgreement.mustAgreeAgain) {
      // Force the user to agree again
      this.depositAgreement.setNotAccepted()
      this.requiredAgreement.uncheck()
      return false
    }
    if (!this.depositAgreement.isAccepted) {
      this.requiredAgreement.uncheck()
      return false
    }
    this.requiredAgreement.check()
    return true
  }
}

  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the visibility component
   * @param {AdminSetWidget} adminSetWidget the control for the adminSet dropdown
   */
  constructor(element, adminSetWidget) {
    this.element = element
    this.adminSetWidget = adminSetWidget
    this.form = element.closest('form')
      this.element.find('.collapse').collapse({ toggle: false })
    element.find("[type='radio']").on('change', () => { this.showForm() })
    // Ensure any disabled options are re-enabled when form submits
    this.form.on('submit', () => { this.enableAllOptions() })
    this.showForm()
    this.limitByAdminSet()
  }

  showForm() {
    this.openSelected()
  }

  // Collapse all Visibility sub-options
  collapseAll() {
      this.element.find('.collapse').collapse('hide');
  }

  // Open the selected Visibility's sub-options, collapsing all others
  openSelected() {
    let selected = this.element.find("[type='radio']:checked")

    let target = selected.data('target')

    if(target) {
      // Show the target suboption and hide all others
        this.element.find('.collapse' + target).collapse('show');
        this.element.find('.collapse:not(' + target + ')').collapse('hide');
    }
    else {
      this.collapseAll()
    }
  }

  // Limit visibility options based on selected AdminSet (if enabled)
  limitByAdminSet() {
    if(this.adminSetWidget) {
      this.adminSetWidget.on('change', (data) => this.restrictToVisibility(data))
      if (this.adminSetWidget.isEmpty()) {
          console.error("No data was passed from the admin set. Perhaps there are no selectable options?")
          return
      }
      this.restrictToVisibility(this.adminSetWidget.data())
    }
  }

  // Restrict visibility and/or release date to match the AdminSet requirements (if any)
  restrictToVisibility(data) {
    // visibility requirement is in HTML5 'data-visibility' attr
    let visibility = data['visibility']
    // if immediate release required, then 'data-release-no-delay' attr will be true
    let release_no_delay = data['releaseNoDelay']
    // release date requirement is in HTML5 'data-release-date' attr
    let release_date = data['releaseDate']
    // if release_date is flexible (i.e. before date), then 'data-release-before-date' attr will be true
    let release_before = data['releaseBeforeDate']

    // Restrictions require either a visibility requirement or a date requirement (or both)
    if(visibility || release_no_delay || release_date) {
      this.applyRestrictions(visibility, release_no_delay, release_date, release_before)
    }
    else {
      this.enableAllOptions()
    }
  }

  // Apply visibility/release restrictions based on selected AdminSet
  applyRestrictions(visibility, release_no_delay, release_date, release_before)
  {
     // If immediate release required or the release date is in the past.
     if(release_no_delay || (release_date && (new Date() > Date.parse(release_date)))) {
       this.requireReleaseNow(visibility)
     }
     // Otherwise if future date and release_before==true, must be released between today and release_date
     else if(release_date && release_before) {
       this.enableReleaseNowOrEmbargo(visibility, release_date, release_before)
     }
     // Otherwise if future date and release_before==false, this is a required embargo (must be released on specific future date)
     else if(release_date) {
       this.requireEmbargo(visibility, release_date)
     }
     // If nothing above matched, then there's no release date required. So, release now or embargo is fine
     else {
       this.enableReleaseNowOrEmbargo(visibility, release_date, release_before)
     }
  }

  // Select given visibility option. All others disabled.
  selectVisibility(visibility) {
    this.element.find("[type='radio'][value='" + visibility + "']").prop("checked", true).prop("disabled", false)
    this.element.find("[type='radio'][value!='" + visibility + "']").prop("disabled", true)
    // Ensure required option is opened in form
    this.showForm()
  }

  // Allow for immediate release or embargo, based on visibility settings (if any)
  enableReleaseNowOrEmbargo(visibility, release_date, release_before) {
    if(visibility) {
      // Enable ONLY the allowable visibility options (specified visibility or embargo)
      this.enableVisibilityOptions([visibility, "embargo"])
    }
    else {
      // Allow all visibility options EXCEPT lease
      this.disableVisibilityOptions(["lease"])
    }

    // Limit valid embargo release dates
    this.restrictEmbargoDate(release_date, release_before)

    // Select Visibility after embargo (if any)
    this.selectVisibilityAfterEmbargo(visibility)
  }

  // Require a specific embargo date (and possibly also specific visibility)
  requireEmbargo(visibility, release_date) {
    // This a required embargo date
    this.selectVisibility("embargo")

    // Limit valid embargo release dates
    this.restrictEmbargoDate(release_date, false)

    // Select Visibility after embargo (if any)
    this.selectVisibilityAfterEmbargo(visibility)
  }

  // Require release now
  requireReleaseNow(visibility) {
    if(visibility) {
      // Select required visibility
      this.selectVisibility(visibility)
    }
    else {
      // No visibility required, but must be released today. Disable embargo & lease.
      this.disableEmbargoAndLease()
    }
  }

  // Disable Embargo and Lease options. Work must be released immediately
  disableEmbargoAndLease() {
    this.disableVisibilityOptions(["embargo","lease"])
  }

  // Enable one or more visibility option (based on array of passed in options),
  // disabling all other options
  enableVisibilityOptions(options) {
    let matchEnabled = this.getMatcherForVisibilities(options)
    let matchDisabled = this.getMatcherForNotVisibilities(options)

    // Enable all that match "matchEnabled" (if any), and disable those matching "matchDisabled"
    if(matchEnabled) {
      this.element.find(matchEnabled).prop("disabled", false)
    }
    this.element.find(matchDisabled).prop("disabled", true)

    this.checkEnabledVisibilityOption()
  }

  // Disable one or more visibility option (based on array of passed in options),
  // disabling all other options
  disableVisibilityOptions(options) {
    let matchDisabled = this.getMatcherForVisibilities(options)
    let matchEnabled = this.getMatcherForNotVisibilities(options)

    // Disable those matching "matchDisabled" (if any), and enable all that match "matchEnabled"
    if(matchDisabled) {
      this.element.find(matchDisabled).prop("disabled", true)
    }
    this.element.find(matchEnabled).prop("disabled", false)

    this.checkEnabledVisibilityOption()
  }

  // Create a jQuery matcher which will match for all the specified options
  // (expects an array of options).
  // This creates a logical OR matcher, whose format looks like:
  // "[type='radio'][value='one'],[type='radio'][value='two']"
  getMatcherForVisibilities(options) {
    let initialMatcher = "[type='radio']"
    let matcher = ""
    // Loop through specified visibility options, creating a logical OR matcher
    for(let i = 0; i < options.length; i++) {
      if(i > 0) {
        matcher += ","
      }
      matcher += initialMatcher + "[value='" + options[i] + "']"
    }
    return matcher
  }

  // Create a jQuery matcher which will match all options EXCEPT the specified options
  // (expects an array of options).
  // This creates a logical AND NOT matcher, whose format looks like:
  // "[type='radio'][value!='one'][value!='two']"
  getMatcherForNotVisibilities(options) {
    let initialMatcher = "[type='radio']"
    let matcher = initialMatcher
    // Loop through specified visibility options, creating a logical AND NOT matcher
    for(let i = 0; i < options.length; i++) {
      matcher += "[value!='" + options[i] + "']"
    }
    return matcher
  }

  // Based on release_date/release_before, limit valid options for embargo date
  // * release_date is a date of format YYYY-MM-DD
  // * release_before is true if dates before release_date are allowabled, false otherwise.
  restrictEmbargoDate(release_date, release_before) {
    let embargoDateInput = this.getEmbargoDateInput()
    // Dates before today are not valid
    embargoDateInput.prop("min", this.getToday());

    if(release_date) {
      // Dates AFTER release_date are not valid
      embargoDateInput.prop("max", release_date);
    }
    else {
      embargoDateInput.prop("max", "");
    }

    // If release before dates are NOT allowed, set exact embargo date and disable field
    if(release_date && !release_before) {
      embargoDateInput.val(release_date)
      embargoDateInput.prop("disabled", true)
    }
    else {
      embargoDateInput.prop("disabled", false)
    }
  }

  // Based on embargo visibility, select required visibility (if any)
  selectVisibilityAfterEmbargo(visibility) {
    let visibilityInput = this.getVisibilityAfterEmbargoInput()
    // If a visibility is required, select it and disable field
    if(visibility) {
      visibilityInput.find("option[value='" + visibility + "']").prop("selected", true)
      visibilityInput.prop("disabled", true)
    }
    else {
      visibilityInput.prop("disabled", false)
    }
  }

  // Ensure all visibility options are enabled
  enableAllOptions() {
    this.element.find("[type='radio']").prop("disabled", false)
    this.getEmbargoDateInput().prop("disabled", false)
    this.getVisibilityAfterEmbargoInput().prop("disabled", false)
  }

  // Get input field corresponding to embargo date
  getEmbargoDateInput() {
    return this.element.find("[type='date'][id$='_embargo_release_date']")
  }

  // Get input field corresponding to visibility after embargo expires
  getVisibilityAfterEmbargoInput() {
    return this.element.find("select[id$='_visibility_after_embargo']")
  }

  // If the selected visibility option is disabled change selection to the
  // least public option that is enabled.
  checkEnabledVisibilityOption() {
    if (this.element.find("[type='radio']:disabled:checked").length > 0) {
      this.element.find("[type='radio']:enabled").last().prop('checked', true)
      // Ensure required option is opened in form
      this.showForm()
    }
  }

  // Get today's date in YYYY-MM-DD format
  getToday() {
    let today = new Date()
    let dd = today.getDate()
    let mm = today.getMonth() + 1  // January is month 0
    let yyyy = today.getFullYear()

    // prepend zeros as needed
    if(dd < 10) {
      dd = '0' + dd
    }
    if(mm < 10) {
      mm = '0' + mm
    }
    return yyyy + '-' + mm + '-' + dd
  }
}

  // Monitors the form and runs the callback when files are added
  constructor(form, callback) {
    this.form = form
    this.element = $('#fileupload')
    this.element.bind('fileuploadcompleted', callback)
    this.element.bind('fileuploaddestroyed', callback)
  }

  get hasFileRequirement() {
    let fileRequirement = this.form.find('li#required-files')
    return fileRequirement.length > 0
  }

  get inProgress() {
    return this.element.fileupload('active') > 0
  }

  get hasFiles() {
    let fileField = this.form.find('input[name="uploaded_files[]"]')
    return fileField.length > 0
  }

  get hasNewFiles() {
    // In a future release hasFiles will include files already on the work plus new files,
    // but hasNewFiles() will include only the files added in this browser window.
    return this.hasFiles
  }
}

  constructor(element) {
    this.element = element
  }

  check() {
    this.element.removeClass('incomplete')
    this.element.addClass('complete')
  }

  uncheck() {
    this.element.removeClass('complete')
    this.element.addClass('incomplete')
  }
}

  // Monitors the form and runs the callback if any of the required fields change
  constructor(form, callback) {
    this.form = form
    this.callback = callback
    this.reload()
  }

  get areComplete() {
    return this.requiredFields.filter((n, elem) => { return this.isValuePresent(elem) } ).length === 0
  }

  isValuePresent(elem) {
    return ($(elem).val() === null) || ($(elem).val().length < 1)
  }

  // Reassign requiredFields because fields may have been added or removed.
  reload() {
    // ":input" matches all input, select or textarea fields.
    this.requiredFields = this.form.find(':input[required]')
    this.requiredFields.change(this.callback)
  }
}

  // Monitors the form and runs the callback if any files are added
  constructor(form, callback) {
    this.agreementCheckbox = form.find('input#agreement')

    // If true, require the accept checkbox to be checked.
    // Tracks whether the user needs to accept again to the depositor
    // agreement. Once the user has manually agreed once she does not
    // need to agree again regardless on how many files are being added.
    this.isActiveAgreement = this.agreementCheckbox.length > 0
    if (this.isActiveAgreement) {
      this.setupActiveAgreement(callback)
      this.mustAgreeAgain = this.isAccepted
    }
    else {
      this.mustAgreeAgain = false
    }
  }

  setupActiveAgreement(callback) {
    this.agreementCheckbox.on('change', callback)
  }

  setNotAccepted() {
    this.agreementCheckbox.prop("checked", false)
    this.mustAgreeAgain = false
  }

  setAccepted() {
    this.agreementCheckbox.prop("checked", true)
  }

  /**
   * return true if it's a passive agreement or if the checkbox has been checked
   */
  get isAccepted() {
    return !this.isActiveAgreement || this.agreementCheckbox[0].checked
  }
}
//= require hyrax/save_work/save_work_control
//= require hyrax/save_work/required_fields
//= require hyrax/save_work/uploaded_files
//= require hyrax/save_work/checklist_item
//= require hyrax/save_work/deposit_agreement
//= require hyrax/save_work/visibility_component

  /**
   * Autocomplete for finding possible related works.
   * @param {jQuery} element - The input field to add autocompete to
   * @param {string} url - The url for the autocompete search endpoint
   * @param {Object} options - optional arguments
   * @param {string} options.excluding - The id to exclude from the search
   */
  constructor(element, url, options = {}) {
    this.url = url;
    this.excludeWorkId = options.excluding;
    this.initUI(element)
  }

  initUI(element) {
    element.select2( {
      minimumInputLength: 2,
      initSelection : (row, callback) => {
        var data = {id: row.val(), text: row.val()};
        callback(data);
      },
      ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
        url: this.url,
        dataType: 'json',
        data: (term, page) => {
          return {
            q: term, // search term
            id: this.excludeWorkId // Exclude this work
          };
        },
        results: this.processResults
      }
    }).select2('data', null);
  }

  // parse the results into the format expected by Select2.
  // since we are using custom formatting functions we do not need to alter remote JSON data
  processResults(data, page) {
    let results = data.map((obj) => {
                             return { id: obj.id, text: obj.label[0] };
                          })
    return { results: results };
  }
}
// This script initializes a jquery-ui autocomplete widget

  constructor(element, url) {
    this.url = url;
    if (this.url !== undefined)
      element.autocomplete(this.options(element))
  }

  options(element) {
    return {
      minLength: 2,

      source: (request, response) => {
        $.getJSON(this.url, {
          q: request.term
        }, response );
      },

      focus: function() {
        // prevent value inserted on focus
        return false;
      },

      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      },

      select: function() {
        if (element.data('autocomplete-read-only') === true) {
          element.attr('readonly', true);
        }
      }
    }
  }
}
// Autocomplete for linked data elements using a select2 autocomplete widget
// After selecting something, the seleted item is immutable

  constructor(element, url) {
    this.url = url
    this.element = element
    this.activate()
  }

  activate() {
    this.element
      .select2(this.options(this.element))
      .on("change", (e) => { this.selected(e) })
  }

  // Called when a choice is made
  selected(e) {
    let result = this.element.select2("data")
    this.element.select2("destroy")
    this.element.val(result.label).attr("readonly", "readonly")
    this.setIdentifier(result.id)
  }

  // Store the uri in the associated hidden id field
  setIdentifier(uri) {
    this.element.closest('.field-wrapper').find('[data-id]').val(uri);
  }

  options(element) {
    return {
      // placeholder: $(this).attr("value") || "Search for a location",
      minimumInputLength: 2,
      id: function(object) {
        return object.id;
      },
      text: function(object) {
        return object.label;
      },
      initSelection: function(element, callback) {
        // Called when Select2 is created to allow the user to initialize the
        // selection based on the value of the element select2 is attached to.
        // Essentially this is an id->object mapping function.

        // TODO: Presently we're just showing a URI, but we should show the label.
        var data = {
          id: element.val(),
          label: element.val()
        };
        callback(data);
      },
      ajax: { // Use the jQuery.ajax wrapper provided by Select2
        url: this.url,
        dataType: "json",
        data: function (term, page) {
          return {
            q: term // Search term
          };
        },
        results: function(data, page) {
          return { results: data };
        }
      }
    }
  }
}



  constructor() {
    this.collectionUtilities = new CollectionUtilities();
    this.setupAddSharingHandler();
    this.sharingAddButtonDisabler();
  }

  /**
   * Set up the handler for adding groups or users via AJAX POSTS at the following location:
   * Collection > Edit > Sharing tab; or
   * Collection Types > Edit > Participants tab
   * @return {void}
   */
  setupAddSharingHandler() {
    const { addParticipants } = this.collectionUtilities;
    const wrapEl = '.form-add-sharing-wrapper';

    $('#participants')
      .find('.edit-collection-add-sharing-button')
      .on('click', {
        wrapEl,
        urlFn: (e) => {
          const $wrapEl = $(e.target).parents(wrapEl);
          return '/dashboard/collections/' + $wrapEl.data('id') + '/permission_template?locale=en';
        }
      },
      addParticipants.handleAddParticipants.bind(addParticipants));
  }

  /**
   * Set up enabling/disabling "Add" button for adding groups and/or users in
   * Edit Collection > Sharing tab
   * @return {void}
   */
  sharingAddButtonDisabler() {
    const { addParticipantsInputValidator } = this.collectionUtilities;
    // Selector for the button to enable/disable
    const buttonSelector = '.edit-collection-add-sharing-button';
    const inputsWrapper = '.form-add-sharing-wrapper';

    $('#participants')
      .find(inputsWrapper)
      .on(
        'change',
        // custom data we need passed into the event handler
        {
          buttonSelector: '.edit-collection-add-sharing-button',
          inputsWrapper
        },
        addParticipantsInputValidator.handleWrapperContentsChange.bind(
          addParticipantsInputValidator
        )
      );
  }
}

  /**
   * Initializes the notification widget on the page and allows
   * updating of the notification count and notification label
   *
   * @param {jQuery} element the notification widget
   */
  constructor(element) {
    this.element = element
    this.counter = element.find('.count')
  }

  update(count, label) {
    this.element.attr('aria-label', label)
    this.counter.html(count)

    if (count === 0) {
      this.counter.addClass('invisible')
    }
    else {
      this.counter.removeClass('invisible')
      this.counter.addClass('label-danger').removeClass('label-default')
    }
  }
}
class TabbedForm {
  /**
   * Bootstrap Tabs use anchors to identify tabs. Anchor of active tab is added as hidden input to given form 
   * so that active tab state can be maintained after Post.
   * @param {form} form element that includes tabs and to which tab anchor will be added as an input
   */
  constructor(form) {
    this.form = form;
  }

  setup() {
    this.refererAnchor = this.addRefererAnchor()
    this.watchActiveTab()
    this.setRefererAnchor($('.nav-tabs li.active a').attr('href'))
  }

  addRefererAnchor() {
    let referer_anchor_input = $('<input>').attr({type: 'hidden', id: 'referer_anchor', name: 'referer_anchor'}) 
    this.form.append(referer_anchor_input)
    return referer_anchor_input
  }

  setRefererAnchor(id) {
    this.refererAnchor.val(id)
  }

  watchActiveTab() {
    $('.nav-tabs a').on('shown.bs.tab', (e) => this.setRefererAnchor($(e.target).attr('href')))
  }
}


  let formTabifier = new TabbedForm(form)
  formTabifier.setup()
}
// The editor for the AdminSets
// Add search for user/group to the edit an admin set's participants page
// Add search for thumbnail to the edit descriptions






    constructor(elem) {
        let url = window.location.pathname.replace('edit', 'files')
        this.thumbnailSelect = new ThumbnailSelect(url, elem.find('#admin_set_thumbnail_id'))

        let participants = new Participants(elem.find('#participants'))
        participants.setup()

        let visibilityTab = new Visibility(elem.find('#visibility'))
        visibilityTab.setup()
        tabifyForm(elem.find('form.edit_admin_set'))
    }
}


    constructor(data) {
        this.userSelector = 'user-activity'
        this.growthSelector = 'dashboard-growth'
        this.statusSelector = 'dashboard-repository-objects'

        if (this.hasSelector(this.userSelector))
            this.userActivity(data.userActivity);
        if (this.hasSelector(this.growthSelector))
            this.repositoryGrowth(data.repositoryGrowth);
        if (this.hasSelector(this.statusSelector))
            this.objectStatus(data.repositoryObjects);

    }

    // Don't attempt to initialize Morris if the selector is not on the page
    // otherwise it raises a "Graph container element not found" error
    hasSelector(selector) {
      return $(`#${selector}`).length > 0;
    }

    // Draws a bar chart of new user signups
    userActivity(data) {
        if (typeof data === "undefined")
            return
        Morris.Bar({
             element: this.userSelector,
             data: data,
             xkey: 'y',
             // TODO: when we add returning users:
             // ykeys: ['a', 'b'],
             // labels: ['New Users', 'Returning'],
             ykeys: ['a'],
             labels: ['New Users', 'Returning'],
             barColors: ['#33414E', '#3FBAE4'],
             gridTextSize: '10px',
             hideHover: true,
             resize: true,
             gridLineColor: '#E5E5E5'
         });
    }

    // Draws a donut chart of active/inactive objects
    objectStatus(data) {
        if (typeof data === "undefined")
            return
        Morris.Donut({
            element: this.statusSelector,
            data: data,
            colors: ['#33414E', '#3FBAE4', '#FEA223'],
            gridTextSize: '9px',
            resize: true
        });
    }

    // Creates a line graph of collections and object in the last 90 days
    repositoryGrowth(data) {
        if (typeof data === "undefined")
            return
        Morris.Line({
           element: this.growthSelector,
           data: data,
           xkey: 'y',
           ykeys: ['a','b'],
           labels: ['Objects','Collections'],
           resize: true,
           hideHover: true,
           xLabels: 'day',
           gridTextSize: '10px',
           lineColors: ['#3FBAE4','#33414E'],
           gridLineColor: '#E5E5E5'
        });
    }
}

   constructor(elem) {
     this.form = elem
   }

   // Fill in the group agent field with the given value
   setAgent(agent) {
       this.form.find('#permission_template_access_grants_attributes_0_agent_id').val(agent)
   }

   // Fill in the group access select box with the given value
   setAccess(access) {
       this.form.find('#permission_template_access_grants_attributes_0_access').val(access)
   }

   // Submit the group participants form
   submitForm() {
       this.form.submit()
   }
}




  // Adds autocomplete to the user search function and enables the
  // "Allow all registered users" button.
  constructor(elem) {
    this.userField = elem.find('#user-participants-form input[type=text]')

    let button = elem.find('button[data-behavior="add-registered-users"]')
    let agents = elem.find('[data-agent]').map((_i, field) => { return field.getAttribute('data-agent') })
    let groupParticipants = new GroupParticipants(elem.find('#group-participants-form'))
    this.registeredUsersButton = new RegisteredUsers(button, agents, groupParticipants)
  }

  setup() {
    this.userField.userSearch()
    this.registeredUsersButton.setup()
  }
}

  constructor(element) {
    this.element = element
  }

  setup() {
    // Watch for changes to "release_period" radio inputs
    let releasePeriodInput = this.element.find("input[type='radio'][name$='[release_period]']")
    $(releasePeriodInput).on('change', () => { this.releasePeriodSelected() })
    this.releasePeriodSelected()

    // Watch for changes to "release_varies" radio inputs
    let releaseVariesInput = this.element.find("input[type='radio'][name$='[release_varies]']")
    $(releaseVariesInput).on('change', () => { this.releaseVariesSelected() })
    this.releaseVariesSelected()
  }

  // Based on the "release_period" radio selected, enable/disable other options
  releasePeriodSelected() {
    let selected = this.element.find("input[type='radio'][name$='[release_period]']:checked")
    
    switch(selected.val()) {
      // If "No Delay" (now) selected
      case "now":
        this.disableReleaseVariesOptions()
        this.disableReleaseFixedDate()
        this.enableVisibilityRestricted()
        break;

      // If "Varies" ("") selected
      case "":
        this.enableReleaseVariesRadio()
        this.disableReleaseFixedDate()
        this.disableVisibilityRestricted()
        // Also check if a release "Varies" sub-option previously selected
        this.releaseVariesSelected()
        break;

      // If "Fixed" selected
      case "fixed":
        this.disableReleaseVariesOptions()
        this.enableReleaseFixedDate()
        this.disableVisibilityRestricted()
        break;

      // Nothing selected
      default:
        this.disableReleaseVariesOptions()
        this.disableReleaseFixedDate()
        this.disableVisibilityRestricted()
    }
  }

  // Based on the "release_varies" radio selected, enable/disable other options
  releaseVariesSelected() {
    let selected = this.element.find("input[type='radio'][name$='[release_varies]']:checked")

    switch(selected.val()) {
      // If before specific date selected
      case "before":
        this.enableReleaseVariesDate();
        this.disableReleaseVariesSelect();
        break;

      // If embargo option selected
      case "embargo":
        this.disableReleaseVariesDate();
        this.enableReleaseVariesSelect();
        break;

      // Nothing selected
      default:
        this.disableReleaseVariesDate();
        this.disableReleaseVariesSelect();
    }
  }

  // Disable ALL sub-options under "Varies"
  disableReleaseVariesOptions() {
    this.disableReleaseVariesRadio()
    this.disableReleaseVariesSelect()
    this.disableReleaseVariesDate()
  }

  // Disable all radio inputs under the release "Varies" option
  disableReleaseVariesRadio() {
    this.element.find("#release-varies input[type='radio'][name$='[release_varies]']").prop("disabled", true)
  }

  // Enable all radio inputs under the release "Varies" option
  enableReleaseVariesRadio() {
    this.element.find("#release-varies input[type='radio'][name$='[release_varies]']").prop("disabled", false)
  }

  // Disable selectbox next to release "Varies" embargo option
  disableReleaseVariesSelect() {
    this.element.find("#release-varies select[name$='[release_embargo]']").prop("disabled", true)
  }

  // Enable selectbox next to release "Varies" embargo option
  enableReleaseVariesSelect() {
    this.element.find("#release-varies select[name$='[release_embargo]']").prop("disabled", false)
  }

  // Disable date input field next to release "Varies" before option
  disableReleaseVariesDate() {
    this.element.find("#release-varies input[type='date'][name$='[release_date]']").prop("disabled", true)
  }

  // Enable date input field next to release "Varies" before option
  enableReleaseVariesDate() {
    this.element.find("#release-varies input[type='date'][name$='[release_date]']").prop("disabled", false)
  }

  // Disable date input field next to release "Fixed" option
  disableReleaseFixedDate() {
    this.element.find("#release-fixed input[type='date'][name$='[release_date]']").prop("disabled", true)
  }

  // Enable date input field next to release "Fixed" option
  enableReleaseFixedDate() {
    this.element.find("#release-fixed input[type='date'][name$='[release_date]']").prop("disabled", false)
  }

  // Disable visibility "Restricted" option (not valid for embargoes)
  disableVisibilityRestricted() {
    this.element.find("input[type='radio'][name$='[visibility]'][value='restricted']").prop("disabled", true)
  }

  // Enable visibility "Restricted" option
  enableVisibilityRestricted() {
    this.element.find("input[type='radio'][name$='[visibility]'][value='restricted']").prop("disabled", false)
  }
}

    // Behaviors for the "Allow all registered users" button.
    constructor(button, agents, groupForm) {
      this.groupForm = groupForm
      this.allUsersButton = button
      this.agents = agents
    }

    // If a row for registered users exists, hide the button
    // Otherwise add behaviors for when the button is clicked
    setup() {
      if (this.hasRegisteredUsers()) {
        this.allUsersButton.hide()
      } else {
        this.allUsersButton.on('click', () => this.addAllUsersAsDepositors())
      }
    }

    // The DOM has some data attributes written that indicate the agent_id
    // Check to see if any of them are for the 'registered' group.
    hasRegisteredUsers() {
      return this.agents.filter((_i, elem) => { return elem == 'registered' }).length > 0
    }

    // Grant deposit access to the 'registered' group
    addAllUsersAsDepositors() {
      this.groupForm.setAgent('registered')
      this.groupForm.setAccess('deposit')
      this.groupForm.submitForm()
    }
}



  // Adds autocomplete to the user search function and enables the
  // "Allow all registered users" button.
  constructor(elem) {
    this.userField = elem.find('#user-participants-form input[type=text]')
  }

  setup() {
    this.userField.userSearch()
  }
}
// Enable/disable sharing APPLIES_TO_NEW_WORKS checkbox based on the state of checkbox SHARABLE

  constructor(element) {
    this.element = element
  }

  setup() {
    this.sharable_checkbox = $("#collection_type_sharable")
    this.applies_to_new_works = $("#collection_type_share_applies_to_new_works")
    this.container = $("#sharable-applies-to-new-works-setting-checkbox-container")
    this.label = $("#sharable-applies-to-new-works-setting-label")

    // Watch for changes to "sharable" checkbox
    $("#collection_type_sharable").on('change', () => { this.sharableChanged() })
    this.sharableChanged()
  }

  // Based on the "sharable" checked/unchecked, enable/disable adjust share_applies_to_new_works checkbox
  sharableChanged() {
    let selected = this.sharable_checkbox.is(':checked')
    let disabled = this.sharable_checkbox.is(':disabled')

    if(selected) {
        // if sharable is selected, then base disabled on whether or not sharable is disabled.  It will be disabled when a
        // collection of this type exists.  In that case, share_applies_to_new_works is readonly, that is, it has the value
        // from the database and is disabled
        this.applies_to_new_works.prop("disabled", disabled)
        if(disabled) {
            this.addDisabledClasses()
        }
        else {
            this.removeDisabledClasses()
        }
    }
    else {
        // if sharable is not selected, then share_applies_to_new_works must be unchecked and disabled so it cannot be changed
        this.applies_to_new_works.prop("checked", false)
        this.applies_to_new_works.prop("disabled", true)
        this.addDisabledClasses()
    }
  }

  /**
   * Add disabled class to elements surrounding the APPLIES TO NEW WORKS checkbox when it is disabled
   */
  addDisabledClasses() {
      this.container.addClass("disabled")
      this.label.addClass("disabled")
      this.applies_to_new_works.addClass("disabled")
  }

    /**
     * Remove disabled class from elements surrounding the APPLIES TO NEW WORKS checkbox when it is not disabled
     */
  removeDisabledClasses() {
      this.container.removeClass("disabled")
      this.label.removeClass("disabled")
      this.applies_to_new_works.removeClass("disabled")
  }
}
// The editor for the CollectionTypeParticipant
// Add search for user/group to the edit an admin set's participants page





    constructor(elem) {
        let participants = new Participants(elem.find('#participants'))
        participants.setup()
        let settings = new Settings(elem.find('#settings'))
        settings.setup()
        tabifyForm(elem.find('form.edit_collection_type'))
    }
}

  /**
   * Initializes the class in the context of an individual table element
   * @param {jQuery} element the table element that this class represents
   */
  constructor(element) {
      this.$element = element;
      this.target = element.data('target')
      this.modal = $(this.target)
      this.form = this.modal.find('form.new-work-select')

      // launch the modal.
      element.on('click', (e) => {
          e.preventDefault()
          this.modal.modal()
          // ensure the type is set for the last clicked element
          // type is either "batch" or "single" (work)
          this.type = element.data('create-type')
          // add custom routing logic when the modal is shown
          this.form.on('submit', this.routingLogic.bind(this))
      });

      // remove the routing logic when the modal is hidden
      this.modal.on('hide.bs.modal', (e) => {
          this.form.unbind('submit')
      });
  }

  // when the form is submitted route to the correct location
  routingLogic(e) {
      e.preventDefault()
      if (this.destination() === undefined)
        return false
      // get the destination from the data attribute of the selected radio button
      window.location.href = this.destination()
  }

  // Each input has two attributes that contain paths, one for the batch and one
  // for a single work.  So, given the value of 'this.type', return the appropriate
  // path.
  destination() {
      return this.form.find('input[type="radio"]:checked').data(this.type)
  }
}



  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {Registry} registry the permissions registry
   */
  constructor(element, registry) {
    this.element = element
    this.registry = registry
    this.depositor = $('#file_owner').data('depositor')
    this.userField = this.element.find("#new_user_name_skel")
    this.permissionField = this.element.find("#new_user_permission_skel")

    // Attach the user search select2 box to the permission form
    this.userField.userSearch()

    // add button for new user
    $('#add_new_user_skel').on('click', (e) => this.addNewUser(e));
  }

  addNewUser(e) {
    e.preventDefault();

    if (!this.userValid()) {
      return this.userField.focus();
    }

    if (this.selectedUserIsDepositor()) {
      return this.addError("Cannot change depositor permissions.")
    }

    if (!this.registry.isPermissionDuplicate(this.userName())) {
      return this.addError("This user already has a permission.")
    }

    var access = this.permissionField.val();
    var access_label = this.selectedPermission().text();
    let agent = new Person(this.userName())
    let grant = new Grant(agent, access, access_label)
    this.registry.addPermission(grant);
    this.reset();
  }

  // clear out the elements to add more
  reset() {
    this.registry.reset();
    this.userField.select2('val', '');
    this.permissionField.val('none');
  }

  userName() {
    return this.userField.val()
  }

  addError(message) {
    this.registry.addError(message);
    this.userField.val('').focus()
  }

  selectedUserIsDepositor() {
    return this.userName() === this.depositor
  }

  userValid() {
    return this.userNameValid() && this.permissionValid()
  }

  userNameValid() {
    return this.userName() !== ""
  }

  permissionValid() {
    return this.selectedPermission().index() !== 0
  }

  selectedPermission() {
    return this.permissionField.find(':selected')
  }
}


  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {String} object_name the name of the object, for constructing form fields (e.g. 'generic_work')
   * @param {String} template_id the the identifier of the template for the added elements
   */
  constructor(element, object_name, template_id) {
    this.object_name = object_name
    this.template_id = template_id
    this.error = $('#permissions_error')
    this.errorMessage = $('#permissions_error_text')
    this.items = []

    // the remove button is only on preexisting grants
    $('.remove_perm').on('click', (evt) => this.removePermission(evt))

  }

  addError(message) {
    this.errorMessage.html(message);
    this.error.removeClass('hidden');
  }

  reset() {
    this.error.addClass('hidden');
  }

  removePermission(evt) {
     evt.preventDefault();
     let button = $(evt.target);
     let container = button.closest('tr');
     container.addClass('hidden'); // do not show the block
     this.addDestroyField(container, button.attr('data-index'));
     this.showPermissionNote();
  }

  addPermission(grant) {
    this.showPermissionNote()
    grant.index = this.nextIndex()
    this.items.push(new RegistryEntry(grant, this, $('#file_permissions'), this.template_id))
  }

  nextIndex() {
      return $('#file_permissions').parent().children().length - 1;
  }

  showPermissionNote() {
     $('#save_perm_note').removeClass('hidden');
  }

  addDestroyField(element, index) {
      $('<input>').attr({
          type: 'hidden',
          name: `${this.fieldPrefix(index)}[_destroy]`,
          value: 'true'
      }).appendTo(element);
  }

  fieldPrefix(counter) {
    return `${this.object_name}[permissions_attributes][${counter}]`
  }

  /*
   * make sure the permission being applied is not for a user/group
   * that already has a permission.
   */
  isPermissionDuplicate(user_or_group_name) {
    let s = `[${user_or_group_name}]`;
    var patt = new RegExp(this.preg_quote(s), 'gi');
    var perms_input = $(`input[name^='${this.object_name}[permissions]']`);
    var perms_sel = $(`select[name^='${this.object_name}[permissions]']`);
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

  preg_quote( str ) {
    return (str+'').replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
  }
}





  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {String} template_id the identifier of the template for the added elements
   */
  constructor(element, template_id) {
    if (element.length === 0) {
      return
    }
    this.element = element

    this.registry = new Registry(this.element, this.object_name(), template_id)
    this.user_controls = new UserControls(this.element, this.registry)
    this.group_controls = new GroupControls(this.element, this.registry)
  }

  // retrieve object_name the name of the object to create
  object_name() {
    return this.element.data('param-key')
  }
}



  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container
   * @param {Registry} registry the permissions registry
   */
  constructor(element, registry) {
    this.element = element
    this.registry = registry
    this.groupField = this.element.find("#new_group_name_skel")
    this.permissionField = this.element.find("#new_group_permission_skel")

    // add button for new group
    $('#add_new_group_skel').on('click', (e) => this.addNewGroup(e));
  }

  addNewGroup(e) {
    e.preventDefault()
    if (!this.groupValid()) {
      return this.groupField.focus();
    }

    var group_name = this.groupField.val();
    var access = this.permissionField.val();
    var access_label = this.selectedPermission().text();

    if (!this.registry.isPermissionDuplicate(this.groupName())) {
      return this.addError("This group already has a permission.")
    }

    let agent = new Group(group_name)
    let grant = new Grant(agent, access, access_label)
    this.registry.addPermission(grant);
    this.reset();
  }
  // clear out the elements to add more
  reset() {
    this.registry.reset();
    this.groupField.val('');
    this.permissionField.val('none');
  }

  groupName() {
    return this.groupField.val()
  }

  addError(message) {
    this.registry.addError(message);
    this.groupField.val('').focus()
  }

  groupValid() {
    return this.selectedGroupValid() && this.permissionValid()
  }

  selectedGroupValid() {
    return this.selectedGroup().index() !== 0
  }

  selectedGroup() {
    return this.groupField.find(':selected')
  }

  permissionValid() {
    return this.selectedPermission().index() !== 0
  }

  selectedPermission() {
    return this.permissionField.find(':selected')
  }
}

  /**
   * Initialize the Person 
   * @param {String} name the name of the agent
   */
  constructor(name) {
    this.type = 'person'
    this.name = name
  }
}


  /**
   * Initialize the registry
   * @param {Grant} grant the grant to display on the form
   * @param {Registry} registry the registry that holds this registry entry.
   */
  constructor(grant, registry, element, template) {
    this.grant = grant
    this.registry = registry
    this.element = element

    let row = this.createPermissionRow(grant, template);
    this.addHiddenPermField(row, grant);
    row.effect("highlight", {}, 3000);
  }

  createPermissionRow(grant, template_id) {
    let row = $(tmpl(template_id, grant));
    this.element.after(row);
    row.find('button').click(function () {
      row.remove();
    });

    return row;
  }

  addHiddenPermField(element, grant) {
      var prefix = this.registry.fieldPrefix(grant.index);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[type]',
          value: grant.type
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[name]',
          value: grant.name
      }).appendTo(element);
      $('<input>').attr({
          type: 'hidden',
          name: prefix + '[access]',
          value: grant.access
      }).appendTo(element);
  }
}

  /**
   * Initialize the Grant 
   * @param {Agent} agent the agent the grant applies to
   * @param {String} access the access level to grant
   * @param {String} accessLabel the access level to display 
   */
  constructor(agent, access, accessLabel) {
    this.agent = agent
    this.access = access
    this.accessLabel = accessLabel
    this.index = 0
  }

  get name() {
    return this.agent.name
  }

  get type() {
    return this.agent.type
  }
}



  /**
   * Initialize the Group 
   * @param {String} name the name of the agent
   */
  constructor(name) {
    this.type = 'group'
    this.name = name
  }
}








  /**
   * initialize the editor behaviors
   * @param {jQuery} element - The form that has a data-param-key attribute
   */
  constructor(element) {
    this.element = element
    this.paramKey = element.data('paramKey') // The work type
    this.adminSetWidget = new AdminSetWidget(element.find('select[id$="_admin_set_id"]'))
    this.sharingTabElement = $('#tab-share')
  }

  init() {
    this.autocomplete()
    this.controlledVocabularies()
    this.sharingTab()
    this.relationshipsControl()
    this.saveWorkControl()
    this.saveWorkFixed()
    this.authoritySelect()
    this.formInProgress()
  }

  // Immediate feedback after work creation, editing.
  formInProgress() {
    $('[data-behavior~=work-form]').on('submit', function(event){
      $('.panel-footer').toggleClass('hidden');
    });
  }
  
  // Used when you have a linked data field that can have terms from multiple
  // authorities.
  authoritySelect() {
      $("[data-authority-select]").each(function() {
          let authoritySelect = $(this).data().authoritySelect
          let options =  {selectBox: 'select.' + authoritySelect,
                          inputField: 'input.' + authoritySelect}
          new AuthoritySelect(options);
      })
  }

  // Autocomplete fields for the work edit form (based_near, subject, language, child works)
  autocomplete() {
      var autocomplete = new Autocomplete()

      $('[data-autocomplete]').each((function() {
        var elem = $(this)
        autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
      }))

      $('.multi_value.form-group').manage_fields({
        add: function(e, element) {
          var elem = $(element)
          // Don't mark an added element as readonly even if previous element was
          // Enable before initializing, as otherwise LinkedData fields remain disabled
          elem.attr('readonly', false)
          autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
        }
      })
  }

  // initialize any controlled vocabulary widgets
  controlledVocabularies() {
    this.element.find('.controlled_vocabulary.form-group').each((_idx, controlled_field) =>
      new ControlledVocabulary(controlled_field, this.paramKey)
    )
  }

  // Display the sharing tab if they select an admin set that permits sharing
  sharingTab() {
    if(this.adminSetWidget && !this.adminSetWidget.isEmpty()) {
      this.adminSetWidget.on('change', () => this.sharingTabVisiblity(this.adminSetWidget.isSharing()))
      this.sharingTabVisiblity(this.adminSetWidget.isSharing())
    }
  }

  sharingTabVisiblity(visible) {
      if (visible)
         this.sharingTabElement.removeClass('hidden')
      else
         this.sharingTabElement.addClass('hidden')
  }

  relationshipsControl() {
      let collections = this.element.find('[data-behavior="collection-relationships"]')
      collections.each((_idx, element) =>
          new RelationshipsControl(element,
                                   collections.data('members'),
                                   collections.data('paramKey'),
                                   'member_of_collections_attributes',
                                   'tmpl-collection').init())

      let works = this.element.find('[data-behavior="child-relationships"]')
      works.each((_idx, element) =>
          new RelationshipsControl(element,
                                   works.data('members'),
                                   works.data('paramKey'),
                                   'work_members_attributes',
                                   'tmpl-child-work').init())
  }

  saveWorkControl() {
      new SaveWorkControl(this.element.find("#form-progress"), this.adminSetWidget)
  }

  saveWorkFixed() {
      // Fixedsticky will polyfill position:sticky
      this.element.find('#savewidget').fixedsticky()
  }
}


/** Class for authority selection on an input field */

    /**
     * Create an AuthoritySelect
     * @param {Editor} editor - The parent container
     * @param {string} selectBox - The selector for the select box
     * @param {string} inputField - The selector for the input field
     */
    constructor(options) {
    	this.selectBox = options.selectBox
    	this.inputField = options.inputField
    	this.selectBoxChange();
    	this.observeAddedElement();
    	this.setupAutocomplete();
    }

    /**
     * Bind behavior for select box
     */
    selectBoxChange() {
      	var selectBox = this.selectBox;
      	var inputField = this.inputField;
        var _this2 = this
      	$(selectBox).on('change', function(data) {
      	    var selectBoxValue = $(this).val();
      	    $(inputField).each(function (data) {
              $(this).data('autocomplete-url', selectBoxValue);
      	       _this2.setupAutocomplete()
            });
      	});
    }

    /**
     * Create an observer to watch for added input elements
     */
    observeAddedElement() {
      	var selectBox = this.selectBox;
      	var inputField = this.inputField;
        var _this2 = this

      	var observer = new MutationObserver((mutations) => {
      	    mutations.forEach((mutation) => {
      		      $(inputField).each(function (data) {
                  $(this).data('autocomplete-url', $(selectBox).val())
      		        _this2.setupAutocomplete();
                });
      	    });
      	});

      	var config = { childList: true };
      	observer.observe(document.body, config);
    }

    /**
     * intialize the Hyrax autocomplete with the fields that you are using
     */
    setupAutocomplete() {
      var inputField = $(this.inputField);
      var autocomplete = new Autocomplete()
      autocomplete.setup(inputField, inputField.data('autocomplete'), inputField.data('autocompleteUrl'))
    }
}

  constructor() {
    this.override_save_button()
    this.elements = []
  }

  override_save_button() {
    Blacklight.onLoad(() => {
      this.save_button.click(this.clicked_save)
    })
  }

  push_changed(element) {
    this.elements.push(element)
    this.elements = $.unique(this.elements)
    this.check_button()
  }

  mark_unchanged(element) {
    this.elements = jQuery.grep(this.elements, (value) => {
      return value != element
    })
    this.check_button()
  }

  check_button() {
    if(this.is_changed && this.save_button.text() == "Save") {
      this.save_button.removeClass("disabled")
    } else {
      this.save_button.addClass("disabled")
    }
  }

  persist() {
    let promises = []
    this.elements.forEach((element) => {
      let result = element.persist()
      promises.push(
        result.then(() => { return element })
        .done((element) => { this.mark_unchanged(element) })
        .fail((element) => { this.push_changed(element) })
      )
    })
    this.save_button.text("Saving...")
    this.save_button.addClass("disabled")
    $.when.apply($, promises).always(() => { this.reset_save_button() })
  }
  
  reset_save_button() {
    this.save_button.text("Save")
    this.check_button()
  }

  get is_changed() {
    return this.elements.length > 0
  }

  get save_button() {
    return $("*[data-action='save-actions']")
  }

  get clicked_save() {
    return (event) => {
      event.preventDefault()
      this.persist()
    }
  }
}

  constructor(save_manager) {
    this.element = $("#sortable")
    this.sorting_info = {}
    this.initialize_sort()
    this.element.data("current-order", this.order)
    this.save_manager = save_manager
    this.initialize_alpha_sort_button()
  }

  initialize_sort() {
    this.element.sortable({handle: ".panel-heading"})
    this.element.on("sortstop", this.stopped_sorting)
    this.element.on("sortstart", this.started_sorting)
  }

  persist() {
    this.element.addClass("pending")
    this.element.removeClass("success")
    this.element.removeClass("failure")
    let persisting = $.post(
      `/concern/${this.class_name}/${this.id}.json`,
      this.params()
    ).done((response) => {
      this.element.data('version', response.version)
      this.element.data("current-order", this.order)
      this.element.addClass("success")
      this.element.removeClass("failure")
    }).fail(() => {
      this.element.addClass("failure")
      this.element.removeClass("success")
    }).always(() => {
      this.element.removeClass("pending")
    })
    return persisting
  }

  params() {
    let params = {}
    params[this.singular_class_name] = {
      "version": this.version,
      "ordered_member_ids": this.order
    }
    params["_method"] = "PATCH"
    return params
  }

  get_sort_position(item) {
    return this.element.children().index(item)
  }

  register_order_change() {
    if(this.order.toString() != this.element.data("current-order").toString()) {
      this.save_manager.push_changed(this)
    } else {
      this.save_manager.mark_unchanged(this)
    }
  }

  get stopped_sorting() {
    return (event, ui) => {
      this.sorting_info.end = this.get_sort_position($(ui.item))
      if(this.sorting_info.end == this.sorting_info.start) {
        return
      }
      this.register_order_change()
    }
  }

  get started_sorting() {
    return (event, ui) => {
      this.sorting_element = $(ui.item)
      this.sorting_info.start = this.get_sort_position(ui.item)
    }
  }

  get id() {
    return this.element.data("id")
  }

  get class_name() {
    return this.element.data("class-name")
  }

  get singular_class_name() {
    return this.element.data("singular-class-name")
  }

  get order() {
    return $("*[data-reorder-id]").map(
      function() {
        return $(this).data("reorder-id")
      }
    ).toArray()
  }

  get version() {
    return this.element.data('version')
  }

  get alpha_sort_button() {
    return $("*[data-action='alpha-sort-action']")
  }

  initialize_alpha_sort_button() {
    let that = this
    this.alpha_sort_button.click(function() { that.sort_alpha() } )
  }

  sort_alpha() {
    // create array of { title, element } objects
    let array = []
    let children = this.element.children().get()
    children.forEach(function(child) {
      let title = $(child).find("input.title").val()
      array.push(
        { title: title,
          element: child }
      )
    })
    // sort array by title of each object
    array.sort(function(o1, o2) {
      let a = o1.title.toLowerCase()
      let b = o2.title.toLowerCase()
      return a < b ? -1 : (a > b ? 1 : 0);
    });
    // replace contents of #sortable with elements from the array
    this.element.empty()
    for (let child of array) {
      this.element.append(child.element)
    }
    this.register_order_change()
  }
}

  /*
   * @param element {jQuery} The field to bind to. Typically instantiated for
   *                         the titles of each member (file_set) object as well
   *                         the hidden work thumbnail_id and representative_id
   * @param notifier {FileManagerMember}
   */
  constructor(element, notifier) {
    this.element = element
    this.notifier = notifier
    this.element.data("initial-value", this.element.val())
    this.element.data("tracker", this)
    this.element.change(this.value_changed)
  }

  reset() {
    this.element.data("initial-value", this.element.val())
    this.notifier.mark_unchanged(this.element)
  }

  get value_changed() {
    return () => {
      if(this.element.val() == this.element.data("initial-value")) {
        this.notifier.mark_unchanged(this.element)
      } else {
        this.notifier.push_changed(this.element)
      }
    }
  }
}

  constructor(element, save_manager) {
    this.element = element
    this.save_manager = save_manager
    this.elements = []
    this.track_label()
  }

  push_changed(element) {
    this.elements.push(element)
    this.elements = $.unique(this.elements)
    this.save_manager.push_changed(this)
  }

  mark_unchanged(element) {
    this.elements = jQuery.grep(this.elements, (value) => {
      return value != element
    })
    if(!this.is_changed) {
      this.save_manager.mark_unchanged(this)
    }
  }

  get is_changed() {
    return this.elements.length > 0
  }

  track_label() {
    new InputTracker(this.element.find("input[type='text']"), this)
  }

  persist() {
    if(this.is_changed) {
      let form = this.element.find("form")
      let deferred = $.Deferred()
      this.element.addClass("pending")
      this.element.removeClass("success")
      this.element.removeClass("failure")
      form.on("ajax:success", () => {
        this.elements.forEach((element) => {
          element.data("tracker").reset()
        })
        deferred.resolve()
        this.element.addClass("success")
        this.element.removeClass("failure")
        this.element.removeClass("pending")
      })
      form.on("ajax:error", () => {
        deferred.reject()
        this.element.addClass("failure")
        this.element.removeClass("success")
        this.element.removeClass("pending")
      })
      // unset the callbacks after they've run so they don't build up
      // and consume memory
      deferred.always(function() {
        form.off('ajax:success')
        form.off('ajax:error')
      })
      form.submit()
      return deferred
    } else {
      return $.Deferred().resolve()
    }
  }
}





  constructor() {
    this.save_manager = this.initialize_save_manager()
    this.sorting()
    this.save_affix()
    this.member_tracking()
    this.sortable_placeholder()
    this.resource_form()
  }

  initialize_save_manager() {
    return(new SaveManager)
  }

  sorting() {
    window.new_sort_manager = new SortManager(this.save_manager)
  }

  save_affix() {
    let tools = $("#file-manager-tools")
    if(tools.length > 0) {
      tools.affix({
        offset: {
          top: $("#file-manager-tools .actions").offset().top,
          bottom: function() {
            return $("#file-manager-extra-tools").outerHeight(true) + $("footer").outerHeight(true)
          }
        }
      })
    }
  }

  member_tracking() {
    let sm = this.save_manager
    $("li[data-reorder-id]").each(function(index, element) {
      var manager_member = new FileManagerMember($(element), sm)
      $(element).data("file_manager_member", manager_member)
    })
  }

  // Initialize a form that represents the parent resource as a whole.
  // For the purpose of CC, this comes with hidden fields for
  // thumbnail_id and representative_id
  // which are synchronized with the radio buttons on each member and then
  // submitted with the SaveManager.
  resource_form() {
    let manager = new FileManagerMember($("#resource-form").parent(), this.save_manager)
    $("#resource-form").parent().data("file_manager_member", manager)
    // Track thumbnail ID hidden field
    new InputTracker($("*[data-member-link=thumbnail_id]"), manager)
    $("#sortable *[name=thumbnail_id]").change(function() {
      let val = $("#sortable *[name=thumbnail_id]:checked").val()
      $("*[data-member-link=thumbnail_id]").val(val)
      $("*[data-member-link=thumbnail_id]").change()
    })
    new InputTracker($("*[data-member-link=representative_id]"), manager)
    $("#sortable *[name=representative_id]").change(function() {
      let val = $("#sortable *[name=representative_id]:checked").val()
      $("*[data-member-link=representative_id]").val(val)
      $("*[data-member-link=representative_id]").change()
    })
  }

  // Keep the ui/sortable placeholder the right size.
  // This keeps the grid a consistent height so when the
  // last row contains 1 object,
  // - an element can be moved into the last spot, and
  // - the footer doesn't jump up.
  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").children("li[data-reorder-id]").first()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }
}

{
    $('input.submits-batches').on('click', ({target}) => {
        let form = $(target).closest("form");
        $.map($(".batch_document_selector:checked"), (document, i) => {
            let id = document.value;
            if (form.children("input[value='" + id + "']").length === 0)
                form.append('<input type="hidden" multiple="multiple" name="batch_document_ids[]" value="' + id + '" />');
        });
    });
}

  /**
   * Initializes the class in the context of an individual select element,
   * and bind its change event to submit the form it is contained within.
   * @param {jQuery} element the select element that this class represents
   */
  constructor(element) {
      this.form = element.parents('form')[0];

      // submit the form to cause the page to render
      element.on('change', (e) => {
          this.form.submit();
      });
  }
}



  constructor(element) {
    this.collectionUtilities = new CollectionUtilities();

    if (element.length > 0) {
      this.handleCollapseToggle();
      this.handleDelete();

      // Edit Collection Type
      this.setupAddParticipantsHandler();
      this.participantsAddButtonDisabler();
    }
  }

  setupAddParticipantsHandler() {
    const { addParticipants } = this.collectionUtilities;
    const wrapEl = '.form-add-participants-wrapper';
    const url = '/admin/collection_type_participants?locale=en';

    $('#participants')
      .find('.add-participants-form input[type="submit"]')
      .on(
        'click',
        {
          wrapEl,
          // This is a callback (seems odd here because just passing in a string value),
          // because other urls need to be calculated with an id or other param only truly
          // known from when we know the clicked element's place in DOM.
          urlFn: e => url
        },
        addParticipants.handleAddParticipants.bind(addParticipants)
      );
  }

  handleCollapseToggle() {
    let $collapseHeader = $('a.collapse-header');
    let $collapseHeaderSpan = $('a.collapse-header').find('span');
    const collapseText = $collapseHeader.data('collapseText');
    const expandText = $collapseHeader.data('expandText');

    // Toggle show/hide of collapsible content on bootstrap toggle events
    $('#collapseAbout').on('show.bs.collapse', () => {
      $collapseHeader.addClass('open');
      $collapseHeaderSpan.html(collapseText);
    });
    $('#collapseAbout').on('hide.bs.collapse', () => {
      $collapseHeader.removeClass('open');
      $collapseHeaderSpan.html(expandText);
    });
  }

  handleDelete() {
    let trData = null;

    // Click delete collections type button in the table row
    $('.delete-collection-type').on('click', event => {
      let dataset = event.target.dataset;
      let collectionType = JSON.parse(dataset.collectionType) || null;
      let hasCollections = dataset.hasCollections === 'true';
      this.handleDelete_event_target = event.target;
      this.collectionType_id = collectionType.id;

      if (hasCollections === true) {
        $('.view-collections-of-this-type').attr(
          'href',
          dataset.collectionTypeIndex
        );
        $('#deleteDenyModal').modal();
      } else {
        $('#deleteModal').modal();
      }
    });

    // Confirm delete collection type
    $('.confirm-delete-collection-type').on('click', event => {
      event.preventDefault();
      $.ajax({
        url: window.location.pathname + '/' + this.collectionType_id,
        type: 'DELETE',
        done: function(e) {
          $(this.handleDelete_event_target)
            .parent('td')
            .parent('tr')
            .remove();
          let defaultButton = $(event.target)
            .parent('div')
            .find('.btn-default');
          defaultButton.trigger('click');
        }
      });
    });

    // Confirm delete collection type
    $('.view-collections-of-this-type').on('click', event => {
      $('#deleteDenyModal').modal('hide');
    });
  }

  /**
   * Set up enabling/disabling "Add" button for adding groups and/or users in
   * Edit Collection Type > Participants tab
   * @return {void}
   */
  participantsAddButtonDisabler() {
    const { addParticipantsInputValidator } = this.collectionUtilities;
    // Selector for the button to enable/disable
    const buttonSelector = '.add-participants-form input[type="submit"]';
    const inputsWrapper = '.form-add-participants-wrapper';

    $('#participants')
      .find(inputsWrapper)
      .on(
        'change',
        // custom data we need passed into the event handler
        {
          buttonSelector,
          inputsWrapper
        },
        addParticipantsInputValidator.handleWrapperContentsChange.bind(
          addParticipantsInputValidator
        )
      );
  }
}




// Controls the behavior of the Collections edit form
// Add search for thumbnail to the edit descriptions

  constructor(elem) {
    let field = elem.find('#collection_thumbnail_id')
    this.thumbnailSelect = new ThumbnailSelect(this.url(), field)
    tabifyForm(elem.find('form.editor'))

    let participants = new Participants(elem.find('#participants'))
    participants.setup()
  }

  url() {
    let urlParts = window.location.pathname.split("/")
    urlParts[urlParts.length - 1] = "files"
    return urlParts.join("/") 
  }
}
/*
 * Represents a Child work or related Collection
 */

    constructor(id, title) {
        this.id = id
        this.title = title
        this.index = 0
    }
}

  /**
   * The function to perform when the dialog is accepted.
   *
   * @callback requestCallback
   */

  /**
   * Initialize the dialog
   * @param {String} text the text for the body of the dialog
   * @param {String} cancel the text for the cancel button
   * @param {String} remove the text for the remove button
   * @param {requestCallback} fn the function to perform if the remove button is pressed
   */
  constructor(text, cancel, remove, fn) {
      this.text = text
      this.cancel = cancel
      this.remove = remove
      this.fn = fn
  }

  template() {
      return `<div class="modal confirm-remove-dialog" tabindex="-1" role="dialog">
              <div class="modal-dialog modal-md" role="document">
              <div class="modal-content">
              <div class="modal-body">${this.text}</div>
              <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">${this.cancel}</button>
                <button type="button" class="btn btn-danger" data-behavior="submit">${this.remove}</button>
              </div>
              </div>
              </div>
              </div>`
  }

  launch() {
      let dialog = $(this.template())
      dialog.find('[data-behavior="submit"]').click(() => {
          dialog.modal('hide');
          dialog.remove();
          this.fn();
      })
      dialog.modal('show')
  }
}


  /**
   * Initialize the registry
   * @param {jQuery} element the jquery selector for the permissions container.
   *                         must be a table with a tbody element.
   * @param {String} object_name the name of the object, for constructing form fields (e.g. 'generic_work')
   * @param {String} templateId the the identifier of the template for the added elements
   */
  constructor(element, objectName, propertyName, templateId) {
    this.objectName = objectName
    this.propertyName = propertyName

    this.templateId = templateId
    this.items = []
    this.element = element
    element.closest('form').on('submit', (evt) => {
        this.serializeToForm()
    });
  }

  // Return an index for the hidden field when adding a new row.
  // A large random will probably avoid collisions.
  nextIndex() {
      return Math.floor(Math.random() * 1000000000000000)
  }

  export() {
      return this.items.map(item => item.export())
  }

  serializeToForm() {
      this.export().forEach((item, index) => {
          this.addHiddenField(index, 'id', item.id)
          this.addHiddenField(index, '_destroy', item['_destroy'])
      })
  }

  addHiddenField(index, key, value) {
      $('<input>').attr({
          type: 'hidden',
          name: `${this.fieldPrefix(index)}[${key}]`,
          value: value
      }).appendTo(this.element);
  }

  // Adds the resource to the first row of the tbody
  addResource(resource) {
      resource.index = this.nextIndex()
      let entry = new RegistryEntry(resource, this, this.templateId)
      this.items.push(entry)
      this.element.prepend(entry.view)
      this.showSaveNote()
  }

  fieldPrefix(counter) {
    return `${this.objectName}[${this.propertyName}][${counter}]`
  }

  showSaveNote() {
    // TODO: we may want to reveal a note that changes aren't active until the resource is saved
  }
}


/**
 * This depends on the passed in element containing `data-autocomplete="work'"`
 * that is also a select2 element.
*/


  /**
   * Initializes the class in the context of an individual table element
   * @param {HTMLElement} element the table element that this class represents.
   * @param {Array} members the members to display in the table
   * @param {String} paramKey the key for the type of object we're submitting (e.g. 'generic_work')
   * @param {String} property the property to submit
   * @param {String} templateId the template identifier for new rows
   */
  constructor(element, members, paramKey, property, templateId) {
    this.element = $(element)
    this.members = this.element.data('members')
    this.registry = new Registry(this.element.find('tbody'), paramKey, property, templateId)
    this.input = this.element.find(`[data-autocomplete]`)
    this.warning = this.element.find(".message.has-warning")
    this.addButton = this.element.find("[data-behavior='add-relationship']")
    this.errors = null
  }

  init() {
    this.bindAddButton();
    this.displayMembers();
  }

  validate() {
    if (this.input.val() === "") {
      this.errors = ['ID cannot be empty.']
    }
  }

  displayMembers() {
    this.members.forEach((elem) =>
      this.registry.addResource(new Resource(elem.id, elem.label))
    )
  }

  isValid() {
    this.validate()
    return this.errors === null
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    this.addButton.on("click", () => this.attemptToAddRow())
  }

  attemptToAddRow() {
      // Display an error when the input field is empty, or if the resource ID is already related,
      // otherwise clone the row and set appropriate styles
      if (this.isValid()) {
        this.addRow()
      } else {
        this.setWarningMessage(this.errors.join(', '))
      }
  }

  addRow() {
    this.hideWarningMessage()
    let data = this.searchData()
    this.registry.addResource(new Resource(data.id, data.text))

    // finally, empty the "add" row input value
    this.clearSearch();
  }

  searchData() {
    return this.input.select2('data')
  }

  clearSearch() {
    this.input.select2("val", '');
  }

  /**
   * Set the warning message related to the appropriate row in the table
   * @param {String} message the warning message text to set
   */
  setWarningMessage(message) {
    this.warning.text(message).removeClass("hidden");
  }

  /**
   * Hide the warning message on the appropriate row
   */
  hideWarningMessage(){
    this.warning.addClass("hidden");
  }
}



    /**
     * Initialize the registry entry
     * @param {Resource} resource the resource to display on the form
     * @param {Registry} registry the registry that holds this registry entry.
     * @param {String} template identifer of the new row template.
     */
    constructor(resource, registry, template) {
        this.resource = resource
        this.registry = registry
        this.view = this.createView(resource, template);
        this.destroyed = false
        //this.view.effect("highlight", {}, 3000);
    }

    export() {
      return { 'id': this.resource.id, '_destroy': this.destroyed }
    }

    // Add a row that has not been persisted
    createView(resource, templateId) {
        let row = $(tmpl(templateId, resource))
        let removeButton = row.find('[data-behavior="remove-relationship"]')
        removeButton.click((e) => {
          e.preventDefault()
          var dialog = new ConfirmRemoveDialog(removeButton.data('confirmText'),
                                               removeButton.data('confirmCancel'),
                                               removeButton.data('confirmRemove'),
                                               () => this.removeResource(e));
          dialog.launch();
        });
        return row;
    }

    // Hides the row and adds a _destroy=true field to the form
    removeResource(evt) {
       evt.preventDefault();
       let button = $(evt.target);
       this.view.addClass('hidden'); // do not show the block
       this.destroyed = true
       this.registry.showSaveNote();
    }
}
/**
 * Generic helper utilities for processing Collection and Collection Type editing
 * @type {Class}
 */

  constructor() {
    this.addParticipantsInputValidator = new AddParticipantsInputValidator();
    this.addParticipants = new AddParticipants();
  }
}

class AddParticipants {
  /**
   * Notes:
   This is a workaround for a scoping issue with 'simple_form' and nested forms in the
   'Edit Collections' partials.  All tabs were wrapped in a 'simple_form'. Nested forms, for example inside a tab partial,
   have behaved erratically, so the pattern has been to remove nested form instances for relatively non-complex forms
   and replace with AJAX requests.  For this instance of Add Sharing > Add user and Add group, seem more complex in how
   the form is built from '@form.permission_template', so since it's not working, but the form is already built, this
   code listens for a click event on the nested form submit button, prevents Default submit behavior, and manually makes
   the form post.
   * @param  {jQuery event} e jQuery event object
   * @return {void}
   */
  handleAddParticipants(e) {
    e.preventDefault();
    const { wrapEl, urlFn } = e.data;
    // This is a callback, because some POST urls might depend on dynamic id variables
    // Send the e event object back and construct any values needed
    const url = urlFn(e);
    const $wrapEl = $(e.target).parents(wrapEl);

    if ($wrapEl.length === 0) {
      return;
    }
    // Get all input values to send in the upcoming POST
    const serialized = $wrapEl.find(':input').serialize();
    if (serialized.length === 0) {
      return;
    }

    $.ajax({
      type: 'POST',
      url: url,
      data: serialized
    })
      .done(function(response) {
        // Success handler here, possibly show alert success if page didn't reload?
      })
      .fail(function(err) {
        console.error(err);
      });
  }
}

/**
 * Handle enabling/disabling "Add" button for adding a user or group when editing a Collection
 * or Collection Type.  Determines whether editable inputs have been filled out or not, then sets button state.
 * @type: {Class}
 */
class AddParticipantsInputValidator {
  /**
   * Check that regular inputs have a non-empty input value
   * @param  {jQuery object} $inputs Inputs which are editable by the user
   * @return {boolean}  Do all inputs passed in have values?
   */
  checkInputsPass($inputs) {
    let inputsPass = true;

    $inputs.each(function(i) {
      if ($(this).val() === '') {
        inputsPass = false;
        return false;
      }
    });
    return inputsPass;
  }

  /**
   * Checks that the select2 input (if it exists) has a non-default value
   * @param  {object} context jQuery $(this) context object
   * @return {boolean} Whether a select2 input has a non-default value, or doesn't exist
   */
  checkSelect2Pass(context) {
    const $select2 = context.find('.select2-container');
    // No select2 element present, so it passes by default
    if ($select2.length === 0) {
      return true;
    }
    const $placeholder = $select2.siblings('[placeholder]');
    const placeholderValue = $placeholder.attr('placeholder');
    const chosenValue = $select2.find('.select2-chosen').text();

    return placeholderValue !== chosenValue;
  }

  /**
   * Handle disabled button state for the 'Add' button for Collections or
   * Collection Type > Edit > Sharing or Participants tab Add Sharing or Add Partipants section
   * @param  {object} event jQuery event object
   * @param {string} event.data.buttonSelector jQuery selector string for row's button
   * @param {string} event.data.inputsWrapper jQuery selector string for the wrapping selector class which holds inputs
   * @return {void}
   */
  handleWrapperContentsChange(event) {
    const { buttonSelector, inputsWrapper } = event.data;
    const $inputsWrapper = $(event.target).parents(inputsWrapper);
    // Get regular inputs for the row
    const $inputs = $inputsWrapper.find('.form-control');
    const $addButton = $inputsWrapper.find(buttonSelector);
    const inputsPass = this.checkInputsPass($inputs);
    const select2Pass = this.checkSelect2Pass($inputsWrapper);

    $addButton.prop('disabled', !(inputsPass && select2Pass));
  }
}
//= require handlebars-v4.0.5







  constructor(element, paramKey) {
      let options = {
        /* callback to run after add is called */
        add:    null,
        /* callback to run after remove is called */
        remove: null,

        controlsHtml:      '<span class=\"input-group-btn field-controls\">',
        fieldWrapperClass: '.field-wrapper',
        warningClass:      '.has-warning',
        listClass:         '.listing',
        inputTypeClass:    '.controlled_vocabulary',

        addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text"></span></button>',
        addText:           'Add another',

        removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"glyphicon glyphicon-remove\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
        removeText:         'Remove',

        labelControls:      true,
      }
      super(element, $.extend({}, options, $(element).data()))
      this.paramKey = paramKey
      this.fieldName = this.element.data('fieldName')
      this.searchUrl = this.element.data('autocompleteUrl')
  }

  // Overrides FieldManager, because field manager uses the wrong selector
  // addToList( event ) {
  //         event.preventDefault();
  //         let $listing = $(event.target).closest('.multi_value').find(this.listClass)
  //         let $activeField = $listing.children('li').last()
  //
  //         if (this.inputIsEmpty($activeField)) {
  //             this.displayEmptyWarning();
  //         } else {
  //             this.clearEmptyWarning();
  //             $listing.append(this._newField($activeField));
  //         }
  //
  //         this._manageFocus()
  // }

  // Overrides FieldManager in order to avoid doing a clone of the existing field
  createNewField($activeField) {
      let $newField = this._newFieldTemplate()
      this._addBehaviorsToInput($newField)
      this.element.trigger("managed_field:add", $newField);
      return $newField
  }

  /* This gives the index for the editor */
  _maxIndex() {
      return $(this.fieldWrapperClass, this.element).length
  }

  // Overridden because we always want to permit adding another row
  inputIsEmpty(activeField) {
      return false
  }

  _newFieldTemplate() {
      let index = this._maxIndex()
      let rowTemplate = this._template()
      let controls = this.controls.clone()//.append(this.remover)
      let row =  $(rowTemplate({ "paramKey": this.paramKey,
                                 "name": this.fieldName,
                                 "index": index,
                                 "class": "controlled_vocabulary" }))
                  .append(controls)
      return row
  }

  get _source() {
      return "<li class=\"field-wrapper input-group input-append\">" +
        "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
        "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
        "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][_destroy]\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"></li>"
  }

  _template() {
      return Handlebars.compile(this._source)
  }

  /**
  * @param {jQuery} $newField - The <li> tag
  */
  _addBehaviorsToInput($newField) {
      let $newInput = $('input.multi-text-field', $newField)
      $newInput.focus()
      this.addAutocompleteToEditor($newInput)
      this.element.trigger("managed_field:add", $newInput)
  }

  /**
  * Make new element have autocomplete behavior
  * @param {jQuery} input - The <input type="text"> tag
  */
  addAutocompleteToEditor(input) {
    var autocomplete = new Autocomplete()
    autocomplete.setup(input, this.fieldName, this.searchUrl)
  }

  // Overrides FieldManager
  // Instead of removing the line, we override this method to add a
  // '_destroy' hidden parameter
  removeFromList( event ) {
      event.preventDefault()
      let field = $(event.target).parents(this.fieldWrapperClass)
      field.find('[data-destroy]').val('true')
      field.hide()
      this.element.trigger("managed_field:remove", field)
  }
}

    // takes a jquery selector for a select field
    // create a custom change event with the data when it changes
    constructor(element) {
        this.changeHandlers = []
        this.element = element
        element.on('change', (e) => {
            this.change(this.data())
        })
    }

    data() {
        return this.element.find(":selected").data()
    }

    isEmpty() {
        return this.element.children().length === 0
    }

    /**
     * returns undefined or true
     */
    isSharing() {
        return this.data()["sharing"]
    }

    on(eventName, handler) {
        switch (eventName) {
            case "change":
                return this.changeHandlers.push(handler)
        }
    }

    change(data) {
        for (let fn of this.changeHandlers) {
          setTimeout(function() { fn(data) }, 0)
        }
    }
}
/**
 * Helper class for internationalization event handling
 */

  constructor() {
    this.addLangClickListener();
  }

  /**
   * Handle the event of selecting a new language from top bar, language select element.
   * This updates the html@lang attribute, which is important for screen readers
   */
  addLangClickListener() {
    $('#user_utility_links')
      .find('a.dropdown-item')
      .on('click', e => {
        let locale = e.target.dataset['locale'];
        if (!locale) {
          return;
        }
        $('html').attr('lang', locale);
      });
  }
}
//= require jquery-ui/core
//= require jquery-ui/widget
//= require jquery-ui/widgets/menu
//= require jquery-ui/widgets/autocomplete
//= require jquery-ui/position
//= require jquery-ui/effect
//= require jquery-ui/effects/effect-highlight
//= require jquery-ui/widgets/sortable

//= require bootstrap/alert
//= require bootstrap/button
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/modal
//= require bootstrap/tooltip
// Popover requires that tooltip be loaded first
//= require bootstrap/popover
//= require bootstrap/tab
// Affix is used for the file manager
//= require bootstrap/affix

//= require select2
//= require fixedsticky

// Graphing libraries
//= require jquery.flot
//= require jquery.flot.time
//= require jquery.flot.selection
//= require morris/raphael-min
//= require morris/morris.min

//= require clipboard

// This is required for Jasmine tests, specifically to polyfill the Symbol() function
//= require babel/polyfill
// CustomElements polyfill is a dependency of time-elements
//= require webcomponentsjs/0.5.4/CustomElements.min
//= require time-elements

//= require action_cable

//= require hyrax/monkey_patch_turbolinks
//= require hyrax/fileupload
// Provide AMD module support
//= require almond
//= require hyrax/notification
//= require hyrax/app
//= require hyrax/config
//= require hyrax/initialize
//= require hyrax/trophy
//= require hyrax/facets
//= require hyrax/featured_works
//= require hyrax/batch_select_all
//= require hyrax/browse_everything
//= require hyrax/search
//= require hyrax/content_blocks
//= require hyrax/nav_safety
//= require hyrax/ga_events
//= require hyrax/select_submit
//= require hyrax/tabs
//= require hyrax/user_search
//= require hyrax/proxy_rights
//= require hyrax/sorting
//= require hyrax/single_use_links_manager
//= require hyrax/dashboard_actions
//= require hyrax/batch
//= require hyrax/flot_stats
//= require hyrax/admin/admin_set_controls
//= require hyrax/admin/admin_set/group_participants
//= require hyrax/admin/admin_set/registered_users
//= require hyrax/admin/admin_set/participants
//= require hyrax/admin/admin_set/visibility
//= require hyrax/admin/collection_type_controls
//= require hyrax/admin/collection_type/participants
//= require hyrax/admin/collection_type/settings
//= require hyrax/collections/editor
//= require hyrax/editor
//= require hyrax/editor/admin_set_widget
//= require hyrax/editor/controlled_vocabulary
//= require hyrax/admin/graphs
//= require hyrax/save_work
//= require hyrax/permissions
//= require hyrax/autocomplete
//= require hyrax/autocomplete/default
//= require hyrax/autocomplete/linked_data
//= require hyrax/autocomplete/resource
//= require hyrax/relationships
//= require hyrax/select_work_type
//= require hyrax/collections
//= require hyrax/collections_v2
//= require hyrax/collection_types
//= require hyrax/collections_utils
//= require hyrax/select_collection_type
//= require hydra-editor/hydra-editor
//= require nestable
//= require hyrax/file_manager/sorting
//= require hyrax/file_manager/save_manager
//= require hyrax/file_manager/member
//= require hyrax/file_manager
//= require hyrax/authority_select
//= require hyrax/sort_and_per_page
//= require hyrax/thumbnail_select
//= require hyrax/batch_select
//= require hyrax/tabbed_form
//= require hyrax/turbolinks_events
//= require hyrax/i18n_helper

// this needs to be after batch_select so that the form ids get setup correctly
//= require hyrax/batch_edit
