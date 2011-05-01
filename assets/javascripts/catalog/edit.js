/*
  We are gradually phasing out these functions in favor of the functions defined in jquery.hydraMetadata.js
*/
(function($) {

  var CatalogEdit = function(options, $element) {

    // PRIVATE VARIABLES

    var $el = $element,
        opts = options,
        $metaDataForm;

    // PRIVATE METHODS

    // constructor
  	function init() {
  	  $metaDataForm = $("form#document_metadata", $el);
  	  $fileAssetsList = $("#file_assets", $el);
      bindDomEvents();
      //$(".editable-container").hydraTextField();
      $(".textile-container").hydraTextileField();
      $(".textile-text").show();
      // Non-fluid inline edit fields
      $(".fedora-checkbox").hydraCheckbox();
      $(".fedora-radio-button").hydraRadioButton();
      setUpDatePicker();
      setUpSliders();
      setUpNewPermissionsForm();
      $("input.editable-edit").hydraTextField();
      $("textarea.editable-edit").hydraTextField();
      $("#add-contributor-box").hydraNewContributorForm();
      $("a.inline").fancybox({
      		'hideOnContentClick': true,
      		'autoDimensions' : false
      	});
  	};

  	function bindDomEvents () {
  	  $metaDataForm.delegate("a.addval.textfield", "click", function(e) {
        $.fn.hydraMetadata.insertTextField(this, e);
        e.preventDefault();
      });
  	  $metaDataForm.delegate("a.addval.grant", "click", function(e) {
				addGrant(this, e);
        e.preventDefault();
      });
      $metaDataForm.delegate("a.addval.textarea", "click", function(e) {
        insertTextileValue(this, e);
        e.preventDefault();
      });
      $metaDataForm.delegate("a.destructive.field", "click", function(e) {
        removeFieldValue(this, e);
        e.preventDefault();
      });
      // $metaDataForm.delegate("a.destructive.contributor", "click", function(e) {
      //   removeContributor(this, e);
      //   e.preventDefault();
      // });
      $(".contributor a.destructive").hydraContributorDeleteButton();

      $(".grant a.destructive").hydraGrantDeleteButton();
      
      $metaDataForm.delegate('select.metadata-dd', 'change', function(e) {
        saveSelect(this);
      });
      
      $fileAssetsList.delegate("a.destructive", "click", function(e) {
        url = $(this).attr("href");
        deleteFileAsset(this, url);
        e.preventDefault();
      });
      
  	};

    //
    // Permissions
    // Use Ajax to add individual permissions entry to the page
    //
    // wait for the DOM to be loaded 
    function setUpNewPermissionsForm () {
        var options = { 
            clearForm: true,        // clear all form fields after successful submit 
            timeout:   2000,
            success:   insertPersonPermission  // post-submit callback 
        };
        // bind 'new_permissions'
        $('#new_permissions').ajaxForm(options); 
    };

    // post-submit callback 
    function insertPersonPermission(responseText, statusText, xhr, $form)  { 
      $("#individual_permissions").append(responseText);
      $('fieldset.slider select').last().selectToUISlider({labelSrc:'text'}).hide();
      $('fieldset.slider:first .ui-slider ol:not(:first) .ui-slider-label').toggle();
    };
    
    function removePermission(element) {
      
    }
    
    function updatePermission(element) {
      $.ajax({
         type: "PUT",
         url: element.closest("form").attr("action"),
         data: element.fieldSerialize(),
         success: function(msg){
     			$.noticeAdd({
             inEffect:               {opacity: 'show'},      // in effect
             inEffectDuration:       600,                    // in effect duration in miliseconds
             stayTime:               6000,                   // time in miliseconds before the item has to disappear
             text:                   "Permissions for "+element.attr("id")+" have been set to "+element.fieldValue(),
             stay:                   false,                  // should the notice item stay or not?
             type:                   'notice'                // could also be error, succes
            });
         },
         error: function(xhr, textStatus, errorThrown){
     			$.noticeAdd({
             inEffect:               {opacity: 'show'},      // in effect
             inEffectDuration:       600,                    // in effect duration in miliseconds
             stayTime:               6000,                   // time in miliseconds before the item has to disappear
             text:                   'Your changes to' + field + ' could not be saved because of '+ xhr.statusText + ': '+ xhr.responseText,   // content of the item
             stay:                   true,                  // should the notice item stay or not?
             type:                   'error'                // could also be error, succes
            });
         }
       });
      // Must submit to permissions controller.  (can't submit as regular metadata update to assets controller update method)
      // because we need to trigger the RightsMetadata update_permissions methods.
    }
    
    function setUpSliders () {
      sliderOpts = {
		    change: function(event, ui) { 
          var associatedSelect = $(ui.handle).parent().prev()
          updatePermission(associatedSelect);
        }
		  }
			$('fieldset.slider select').each(function(index) {
				$(this).selectToUISlider({
				  labelSrc:'text',
				  sliderOptions: sliderOpts
				}).hide();
			});
			$('fieldset.slider:first .ui-slider ol:not(:first) .ui-slider-label').toggle();
    }
    
  	function setUpInlineEdits () {
  	  fluid.inlineEdits("body", {
          selectors : {
            editables : ".editable-container",
            text : ".editable-text",
            edit: ".editable-edit"           
          },
          componentDecorators: {
            type: "fluid.undoDecorator"
          },
          listeners : {
            onFinishEdit : hydraFinishEditListener,
            modelChanged : hydraModelChangedListener
          },
          defaultViewText: "click to edit"
      });
  	};

		// 
		// Grants
		// 
		//
		// Use Ajax to add a grant to the page
		//
		function setUpNewGrantForm () {
		  $(".addval.grant").click(function() {
		    addGrant();
		  });
		}

		function addGrant() {
		  var content_type = $("form#document_metadata > input#content_type").first().attr("value");
		  var insertion_point_selector = "#grants";
		  var url = $("form#document_metadata").attr("action").split('?')[0] + '/grants';
		  $.post(url, {content_type: content_type},function(data) {
				$(insertion_point_selector).append(data);
		    fluid.inlineEdits("#"+$(data).attr("id"), {
		        selectors : {
		          editables : ".editable-container",
		          text : ".editable-text",
		          edit: ".editable-edit"
		        },
		        componentDecorators: {
		          type: "fluid.undoDecorator"
		        },
		        listeners : {
		          onFinishEdit : hydraFinishEditListener,
		          modelChanged : hydraModelChangedListener
		        },
		        defaultViewText: "click to edit"
		    });

		  });
		};

		function removeGrant(element) {
		  var content_type = $("form#document_metadata > input#content_type").first().attr("value");
		  var url = $(element).attr("href");
		  var $grantNode = $(element).closest(".grant")

		  $.ajax({
		    type: "DELETE",
		    url: url,
		    dataType: "html",
		    beforeSend: function() {
					$contributorNode.animate({'backgroundColor':'#fb6c6c'},300);
				},
				success: function() {
					$contributorNode.slideUp(300,function() {
						$contributorNode.remove();
					});
		    }        
		  });

		};
  	
    // 
    // Contributors
    // 
    //
    // Use Ajax to add a contributor to the page
    //
    function setUpNewContributorForm () {
      $("#re-run-add-contributor-action").click(function() {
        addContributor("person");
      });
      $("#add_person").click(function() {
        addContributor("person");
      });
      $("#add_organization").click(function() {
        addContributor("organization");
      });
      $("#add_conference").click(function() {
        addContributor("conference");
      });
    }
    
    function addContributor(type) {
      var content_type = $("form#new_contributor > input#content_type").first().attr("value");
      var insertion_point_selector = "#"+type+"_entries";
      var url = $("form#new_contributor").attr("action");
      
      $.post(url, {contributor_type: type, content_type: content_type},function(data) {
        $(insertion_point_selector).append(data);
        fluid.inlineEdits("#"+$(data).attr("id"), {
            selectors : {
              editables : ".editable-container",
              text : ".editable-text",
              edit: ".editable-edit"
            },
            componentDecorators: {
              type: "fluid.undoDecorator"
            },
            listeners : {
              onFinishEdit : hydraFinishEditListener,
              modelChanged : hydraModelChangedListener
            },
            defaultViewText: "click to edit"
        });
        
      });
    };
    
    function removeContributor(element) {
      var content_type = $("form#new_contributor > input#content_type").first().attr("value");
      var url = $(element).attr("href");
      var $contributorNode = $(element).closest(".contributor")
      
      $.ajax({
        type: "DELETE",
        url: url,
        dataType: "html",
        beforeSend: function() {
  				$contributorNode.animate({'backgroundColor':'#fb6c6c'},300);
  			},
  			success: function() {
  				$contributorNode.slideUp(300,function() {
  					$contributorNode.remove();
  				});
        }        
      });
      
    };
    
  	// grabs datastream name and field name from the data-datastream-name and rel attributes on the input.textile-edit
  	// grabs the submit url from the closest form, appending .textile as the format on the URL
    // Hides the input.textile-edit
    // serializes applicable field selectors and adds them to the submit data
    // 
  	function setUpTextileEditables() {
      $('.textile-container', $el).each(function(index) {
        // var $textileContainer = $(this).closest("dd");
        var $textileContainer = $(this);  
        var $editNode = $(".textile-edit", $textileContainer).first();
        var datastreamName = $editNode.attr('data-datastream-name');

        var $closestForm = $textileContainer.closest("form");
        var assetUrl = $closestForm.attr("action");
        
        var fieldName = $editNode.attr("rel");
        // var field_param = $editNode.fieldSerialize();
        var content_type_param = $("input#content_type", $closestForm).fieldSerialize();
        var field_selectors = $("input.fieldselector[rel="+$editNode.attr("rel")+"]").fieldSerialize()
        var params = content_type_param + "&" + field_selectors
        
        var submitUrl = appendFormat(assetUrl, {format: "textile"}) + params

        var $textiles = $(".textile-edit", $textileContainer);
        $textiles.each(function(index) {
          var $this = $(this);
          var name = $this.attr("name");
          var params = {
            datastream: datastreamName,
            field: fieldName,
            field_index: index
          }                    
          $this.siblings().first().editable(submitUrl, {
            method    : "PUT",
            indicator : "<img src='/plugin_assets/hydra-head/images/ajax-loader.gif'>",
            type      : "textarea",
            submit    : "OK",
            cancel    : "Cancel",
            tooltip   : "Click to edit " + fieldName.replace(/_/, ' ') + "...",
            placeholder : "click to edit",
            onblur    : "ignore",
            name      : name,
            id        : "field_id",
            height    : "100",
            loadurl  : assetUrl + "?" + $.param(params)
          });
          $this.hide();
        });
      });
    };

    function setUpDatePicker () {      
      $('div.date-select', $el).each(function(index) {
        var $this = $(this);
        var opts = $.extend($this.data("opts"), {
          showWeeks:true,
          statusFormat:"l-cc-sp-d-sp-F-sp-Y",
          callbackFunctions:{
            "dateset": [saveDateWidgetEdit]
          }
        });
        datePickerController.createDatePicker(opts);
      });
    };

    // Inserting and removing simple inline edits
    function insertValue(element, event) {
      $element = $(element)
      var fieldName = $element.attr("rel");
      var datastreamName = $element.attr('data-datastream-name');
      
      var values_list = $("ol[rel="+fieldName+"]");
      var new_value_index = values_list.children('li').size();
      var unique_id = fieldName + "_" + new_value_index;
      
      var $item = $('<li class=\"editable-container field\" id="'+unique_id+'-container"><a href="" class="destructive field" title="Delete">Delete</a><span class="editable-text" id="'+unique_id+'-text"></span><input class="editable-edit" id="'+unique_id+'" data-datastream-name="'+datastreamName+'" rel="'+fieldName+'" name="asset['+datastreamName+'][' + fieldName + '][' + new_value_index + ']"/></li>');
      $item.appendTo(values_list);
      var newVal = fluid.inlineEdit($item, {
                    selectors: {
                      editables : ".editable-container",
                      text : ".editable-text",
                      edit: ".editable-edit"
                    },
                    listeners : {
                      onFinishEdit : hydraFinishEditListener,
                      modelChanged : hydraModelChangedListener
                    }	,
					          defaultViewText: "click to edit"
                  });
                  newVal.edit();
    };

    function insertTextileValue(element, event) {
      var fieldName = $(element).closest("dt").next('dd').attr("id");
      var datastreamName = $(element).closest("dt").next('dd').attr("data-datastream-name");
      var $values_list = $(element).closest("dt").next("dd").find("ol");
      var new_value_index = values_list.children('li').size();
      var unique_id =  "asset_" + fieldName + "_" + new_value_index;
      
      var assetUrl = $values_list.closest("form").attr("action");

      var $item = jQuery('<li class=\"field_value textile_value\" name="asset[' + fieldName + '][' + new_value_index + ']"><a href="" class="destructive"><img src="/images/delete.png" border="0" /></a><div class="textile" id="'+fieldName+'_'+new_value_index+'">click to edit</div></li>');
      $item.appendTo(values_list);

      $("div.textile", $item).editable(assetUrl+"&format=textile", {
          method    : "PUT",
          indicator : "<img src='/plugin_assets/hydra-head/images/ajax-loader.gif'>",
          loadtext  : "",
          type      : "textarea",
          submit    : "OK",
          cancel    : "Cancel",
          // tooltip   : "Click to edit #{field_name.gsub(/_/, ' ')}...",
          placeholder : "click to edit",
          onblur    : "ignore",
          name      : "asset["+fieldName+"]["+new_value_index+"]",
          id        : "field_id",
          height    : "100",
          loadurl  : assetUrl+"?datastream="+datastreamName+"&field="+fieldName+"&field_index="+new_value_index
      });

    };

    //Handlers for when you're done editing and want values to submit to the app.
    function hydraFinishEditListener(newValue, oldValue, editNode, viewNode) {
      // Only submit if the value has actually changed.
      if (newValue != oldValue) {
        var result = hydraSaveEdit(editNode, newValue)
      }
      return result;
    };

    // Handler for ensuring that the undo decorator's actions will be submitted to the app.
    function hydraModelChangedListener(model, oldModel, source) {
      
      // this was a really hacky way of checking if the model is being changed by the undo decorator
      if (source && source.options.selectors.undoControl) {
        var result = hydraSaveEdit(source.component.edit);
        return result;
      }
    };

    function saveSelect(element) {
      if (element.value != '') {
        hydraSaveEdit(element);
      }
    };

    function saveDateWidgetEdit(callback) {
        name = $("#"+callback["id"]).parent().attr("name");
        value = callback["yyyy"]+"-"+callback["mm"]+"-"+callback["dd"];
        saveEdit(name , value);
    };

    // Remove the given value from its corresponding metadata field.
    // @param {Object} element - the element containing a value that should be removed.  element.name must be in format document[field_name][index]
    function removeFieldValue(element) {
      // set the value to an empty string & call hydraSaveEdit
      $editNode = $(element).siblings("input.edit").first();
      $editNode.attr("value", "");
      hydraSaveEdit($editNode, "");
			$(element).parent('li').remove();	
    }
    
    function hydraSaveEdit(editNode, newValue) {
      $editNode = $(editNode)
      var $closestForm = $editNode.closest("form");
      var url = $closestForm.attr("action");
      var field_param = $editNode.fieldSerialize();
      var content_type_param = $("input#content_type", $closestForm).fieldSerialize();
      var field_selectors = $("input.fieldselector[rel="+$editNode.attr("rel")+"]").fieldSerialize()
      
      var params = field_param + "&" + content_type_param + "&" + field_selectors
      
      $.ajax({
        type: "PUT",
        url: url,
        dataType : "json",
        data: params,
        success: function(msg){
    			$.noticeAdd({
            inEffect:               {opacity: 'show'},      // in effect
            inEffectDuration:       600,                    // in effect duration in miliseconds
            stayTime:               6000,                   // time in miliseconds before the item has to disappear
            text:                   "Your edit to "+ msg.updated[0].field_name +" has been saved as "+msg.updated[0].value+" at index "+msg.updated[0].index,   // content of the item
            stay:                   false,                  // should the notice item stay or not?
            type:                   'notice'                // could also be error, succes
           });
        },
        error: function(xhr, textStatus, errorThrown){
    			$.noticeAdd({
            inEffect:               {opacity: 'show'},      // in effect
            inEffectDuration:       600,                    // in effect duration in miliseconds
            stayTime:               6000,                   // time in miliseconds before the item has to disappear
            text:                   'Your changes to' + $editNode.attr("rel") + ' could not be saved because of '+ xhr.statusText + ': '+ xhr.responseText,   // content of the item
            stay:                   true,                  // should the notice item stay or not?
            type:                   'error'                // could also be error, succes
           });
        }
      });
    };
    
    
    // Submit a destroy request
    function deleteFileAsset(el, url) {
      var $el = $(el);
      var $fileAssetNode = $el.closest(".file_asset");
      $.ajax({
        type: "DELETE",
        url: url,
        beforeSend: function() {
  				$fileAssetNode.animate({'backgroundColor':'#fb6c6c'},300);
  			},
  			success: function() {
  				$fileAssetNode.slideUp(300,function() {
  					$fileAssetNode.remove();
  				});
				}
      });
    }
    
    /*
    * Simplified function based on jQuery AppendFormat plugin by Edgar J. Suarez
    * http://github.com/edgarjs/jquery-append-format
    */
    function appendFormat(url,options) {
       var qs = '';
       var baseURL;
       
       if(url.indexOf("?") !== -1) {
           baseURL = url.substr(0, url.indexOf("?"));
           qs = url.substr(url.indexOf("?"), url.length);
       } else {
           baseURL = url;
      }
      if((/\/.*\.\w+$/).exec(baseURL) && !options.force) {
          return baseURL + qs;
      } else {
          return baseURL + '.' + options.format + qs;
      }
    }
    // PUBLIC METHODS


    // run constructor;
    init();
  };

  // jQuery plugin method
  $.fn.catalogEdit = function(options) {
    return this.each(function() {
      var $this = $(this);

      // If not already stored, store plugin object in this element's data
      if (!$this.data('catalogEdit')) {
        $this.data('dashboardIndex', new CatalogEdit(options, $this));
      }
    });
  };

})(jQuery);


$(function() {
    Hydrangea.FileUploader.setUp();
  });
