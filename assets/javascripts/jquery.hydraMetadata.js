(function($) {
 
  
   $.fn.hydraMetadata = {

     /*
     *  hydraMetadata.insertTextField
     *  Insert a Hydra editable text field
     */
     insertTextField: function(element, event) {
       $element = $(element);
       var fieldName = $element.attr("rel");
       var datastreamName = $element.attr('data-datastream-name');

       var values_list = $("ol[rel="+fieldName+"]");
       var new_value_index = values_list.children('li').size();
       var unique_id = fieldName + "_" + new_value_index;

       //var $item = $('<li class=\"editable-container field\" id="'+unique_id+'-container"><a href="" class="destructive field" title="Delete \'[NAME OF THING] in hydraMetadata.insertTextField\'">Delete</a><span class="editable-text text" id="'+unique_id+'-text"></span><input class="editable-edit edit" id="'+unique_id+'" data-datastream-name="'+datastreamName+'" rel="'+fieldName+'" name="asset['+datastreamName+'][' + fieldName + '][' + new_value_index + ']"/></li>');
       var $item = $('<li class=\"editable-container field\" id="'+unique_id+'-container"><a href="" class="destructive field" title="Delete">Delete</a><span class="editable-text text" id="'+unique_id+'-text"></span><input class="editable-edit edit" id="'+unique_id+'" data-datastream-name="'+datastreamName+'" rel="'+fieldName+'" name="asset['+datastreamName+'][' + fieldName + '][' + new_value_index + ']"/></li>');
			$item.appendTo(values_list);

       var newVal = fluid.inlineEdit($item, {
                     selectors: {
                       editables : ".editable-container_PPP",
                       text : ".editable-text",
                       edit: ".editable-edit_PPP"
                     },
                     listeners : {
                       onFinishEdit : jQuery.fn.hydraMetadata.fluidFinishEditListener,
                       modelChanged : jQuery.fn.hydraMetadata.fluidModelChangedListener
                     }
                   });
                  // added the following for completion of neutering the inlineEdit functionality
                  $(".editable-text").hide();
                  $("#"+unique_id).hydraTextField();
                   //newVal.edit();
     },
     
     /*
     *  hydraMetadata..insertTextileField
     *  Insert a Hydra editable textile field
     */
     insertTextileField: function(element, event) {
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

     },
     
     // Remove the given value from its corresponding metadata field.
     // @param {Object} element - the element containing a value that should be removed.  element.name must be in format document[field_name][index]
     deleteFieldValue: function(element) {
       // set the value to an empty string & call $.fn.hydraMetadata.saveEdit
       $editNode = $(element).siblings("input.edit").first();
       $editNode.attr("value", "");
       $.fn.hydraMetadata.saveEdit($editNode, "");
     },

     addGrant: function() {
       var content_type = $("formr > input#content_type").first().attr("value");
       var url = $("form#document_metadata").attr("action").split('?')[0];

       $.post(url, {content_type: content_type},function(data) {
         $("a.destructive", $inserted).hydraContributorDeleteButton();
       });
     },
          
     addContributor: function(type) {
       var content_type = $("form#new_contributor > input#content_type").first().attr("value");
       var contributors_group_selector = "."+type+".contributor";
       var url = $("form#new_contributor").attr("action");
      
       $.post(url, {contributor_type: type, content_type: content_type},function(data) {
         if ($(contributors_group_selector).size() == 0) {
           $("ol#contributors").append(data);
         } else {
           $(contributors_group_selector).last().after(data);
         }
         $inserted = $(contributors_group_selector).last();
         //$(".editable-container", $inserted).hydraTextField();
         $(".editable-edit.edit", $inserted).hydraTextField();
         $("a.destructive", $inserted).hydraContributorDeleteButton();
				$("#re-run-add-contributor-action").val("Add a " + type);
       });
      
			return false;
     },
     
     addPersonPermission: function(responseText, statusText, xhr, $form)  { 
       $("#individual_permissions").append(responseText);
       $('fieldset.slider select').last().selectToUISlider({labelSrc:'text'}).hide();
       $('fieldset.slider:first .ui-slider ol:not(:first) .ui-slider-label').toggle();
     },
     
     updatePermission: function(element) {
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
     },

     deleteGrant: function(element) {
       var content_type = $("form#document_metadata > input#content_type").first().attr("value");
       var url = $(element).attr("href");
			 var $grantNode = $(element).closest(".grant");
       $.ajax({
         type: "DELETE",
         url: url,
         dataType: "html",
         beforeSend: function() {
   				$grantNode.animate({'backgroundColor':'#fb6c6c'},300);
         },
   			 success: function() {
           $grantNode.slideUp(300,function() {
             $grantNode.remove();
   				});
         }        
       });
       
     },
     
     deleteContributor: function(element) {
       var content_type = $("form#new_contributor > input#content_type").first().attr("value");
       var url = $(element).attr("href");
       var $contributorNode = $(element).closest(".contributor");

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
       
     },
     
     saveSelect: function(element) {
       if (element.value != '') {
         $.fn.hydraMetadata.saveEdit(element);
       }
     },

     saveCheckbox: function(element) {
         $.fn.hydraMetadata.saveEdit(element);
     },
     
     saveDateWidgetEdit: function(callback) {
         name = $("#"+callback["id"]).parent().attr("name");
         value = callback["yyyy"]+"-"+callback["mm"]+"-"+callback["dd"];
         saveEdit(name , value);
     },
     
     /*
     *  hydraMetadata.fluidFinishEditListener
     *  modelChangedListener for Fluid Components
     *  Purpose: Handler for when you're done editing and want values to submit to the app.     
     *  Triggers hydraMetadata.saveEdit()
     */
     fluidFinishEditListener: function(newValue, oldValue, editNode, viewNode) {
       // Only submit if the value has actually changed.
       if (newValue != oldValue) {
         var result = $.fn.hydraMetadata.saveEdit(editNode, newValue);
       }
			
       return result;
     },
     
     /*
     *  hydraMetadata.fluidModelChangedListener
     *  modelChangedListener for Fluid Components
     *  Purpose: Handler for ensuring that the undo decorator's actions will be submitted to the app.
     *  Triggers hydraMetadata.saveEdit()
     */
     fluidModelChangedListener: function(model, oldModel, source) {

       // this was a really hacky way of checking if the model is being changed by the undo decorator
       if (source && source.options.selectors.undoControl) {
         var result = $.fn.hydraMetadata.saveEdit(source.component.edit);
         return result;
       }
     },
     
     /*
     *  Save the values from a Hydra editable field (fedora_textfield, fedora_textarea, fedora_textile, fedora_select, fedora_date)
     *
     */
    saveEdit: function(editNode) {
       $editNode = $(editNode);
       var $closestForm = $editNode.closest("form");
       var url = $closestForm.attr("action");
       var field_param = $editNode.fieldSerialize();
       var content_type_param = $("input#content_type", $closestForm).fieldSerialize();
       var field_selectors = $("input.fieldselector[rel="+$editNode.attr("rel")+"]").fieldSerialize();
       var params = field_param + "&" + content_type_param + "&" + field_selectors + "&_method=put";
       
       // FOR UVA
       var field_id = field_param.match(/person_._computing_id/);
       if (field_id) { 
         ix = field_id[0].match(/\d+/);
         field = field_id[0];
       }
       // Show processing in Progress
       switch($editNode.attr("id")) {
       case "title_info_main_title":
         var titleUpdated = true;
         $.fn.hydraProgressBox.showProcessingInProgress('step_1_label');
         break;
       case "person_0_first_name":
         var personUpdated = true;
         $.fn.hydraProgressBox.showProcessingInProgress('step_1_label');
         break;
       case "person_0_last_name":
         var personUpdated = true;
         $.fn.hydraProgressBox.showProcessingInProgress('step_1_label');
         break;
       case "copyright_uvalicense":
         var licenseUpdated = true;
         $.fn.hydraProgressBox.showProcessingInProgress('step_1_label');
         break;
       case "journal_0_title_info_main_title":
         var journalTitleUpdated = true;
         $.fn.hydraProgressBox.showProcessingInProgress('step_2_label');
         break;
       default:
       }

       $.ajax({
         type: "PUT",
         url: url,
         dataType : "json",
         data: params,
         success: function(msg){
          // if this is computing id field, need to update the first_name, last_name and institution
          if (field_id) {
            $.fn.hydraMetadata.getPersonInformation(url,ix);
          }
          
          
          // Update progress box for step 1
          if (titleUpdated || personUpdated || licenseUpdated) {
            var stepOneReady = $.fn.hydraProgressBox.testStepOneReadiness();
            $.fn.hydraProgressBox.checkUncheckProgress('step_1_label', stepOneReady);
          }
          
          // Update progress box for step 2
          if (journalTitleUpdated) {
            var stepTwoReady = $.fn.hydraProgressBox.testStepTwoReadiness();
            $.fn.hydraProgressBox.checkUncheckProgress('step_2_label', stepTwoReady);
          }
          // Check if releasable, and if so enable the submit button
          $.fn.hydraProgressBox.testReleaseReadiness();
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
     },
    
    /*
    *  Update the values of first_name, last_name and institution - called upon successful completion of computing_id field
    *
    */
    getPersonInformation: function(url,ix) {
      $.ajax({
        type: "GET",
        url: url+"&field=person_"+ix+"_first_name",
        success: function(msg){
          $("#person_"+ix+"_first_name").val(msg);
          $("#person_"+ix+"_first_name-text").text(msg);
          $("#person_"+ix+"_first_name-text").removeClass("fl-inlineEdit-invitation-text");
          var authorProvided = (msg.length > 0);
          $.fn.hydraProgressBox.checkUncheckProgress('step_1_label', authorProvided);
        }
      });
      $.ajax({
        type: "GET",
        url: url+"&field=person_"+ix+"_last_name",
        success: function(msg){
          $("#person_"+ix+"_last_name").val(msg);
          $("#person_"+ix+"_last_name-text").text(msg);
          $("#person_"+ix+"_last_name-text").removeClass("fl-inlineEdit-invitation-text");
          var authorProvided = (msg.length > 0);
          $.fn.hydraProgressBox.checkUncheckProgress('step_1_label', authorProvided);
        }
      });
      $.ajax({
        type: "GET",
        url: url+"&field=person_"+ix+"_institution",
        success: function(msg){
          $("#person_"+ix+"_institution").val(msg);
          $("#person_"+ix+"_institution-text").text(msg);
          $("#person_"+ix+"_institution-text").removeClass("fl-inlineEdit-invitation-text");
        }
      });
      $.ajax({
        type: "GET",
        url: url+"&field=person_"+ix+"_description",
        success: function(msg){
          $("#person_"+ix+"_description").val(msg);
          $("#person_"+ix+"_description-text").text(msg);
          $("#person_"+ix+"_description-text").removeClass("fl-inlineEdit-invitation-text");
        }
      });
    },

     /*
     *  Save the values from a Hydra editable field (fedora_textfield, fedora_textarea, fedora_textile, fedora_select, fedora_date)
     *
     */
    updateNode: function(refreshNode) {
       $refreshNode = $(refreshNode);
       var $closestForm = $editNode.closest("form");
       var url = $closestForm.attr("action");
       var field_param = $editNode.fieldSerialize();
       var content_type_param = $("input#content_type", $closestForm).fieldSerialize();
       var field_selectors = $("input.fieldselector[rel="+$editNode.attr("rel")+"]").fieldSerialize();

       var params = field_param + "&" + content_type_param + "&" + field_selectors + "&_method=put";
       
       $.ajax({
         type: "GET",
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
     },
     
     // Submit a destroy request
     deleteFileAsset: function(el) {
       var $fileAssetNode = $(el).closest(".file_asset");
       var url = $(el).attr("href");
       
       $.ajax({
         type: "DELETE",
         url: url,
         beforeSend: function() {
   				$fileAssetNode.animate({'backgroundColor':'#fb6c6c'},300);
   			},
   			success: function() {
   				$fileAssetNode.slideUp(300,function() {
   					$fileAssetNode.remove();
   					// UVA Libra -- update progress box if files deleted.
     				var fileUploaded = ($("#file_assets tr.file_asset").length > 0);
     				$.fn.hydraProgressBox.checkUncheckProgress('step_1_label', fileUploaded);
   				});         
 				}
       });
     },
     
     /*
     * Hide labels on all sliders in a set except for the labels on the first slider.
     */
     configureSliderLabels: function() {
       	$('fieldset.slider:first .ui-slider ol:not(:first) .ui-slider-label').toggle();
     },
     
     /*
     * Simplified function based on jQuery AppendFormat plugin by Edgar J. Suarez
     * http://github.com/edgarjs/jquery-append-format
     */
     appendFormat: function(url,options) {
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
     
   };
   
   
   /*
   *  jQuery Plugin Functions
   */
   
   /*
   * Initialize the element as a Hydra Editable TextField
   */
   $.fn.hydraTextField = function(settings) {
      this.each(function() {
       $(this).unbind('blur').bind('blur', function(e) {
         if ($(this).hasClass("data-changed")) {
           $.fn.hydraMetadata.saveEdit(this,e);
           $(this).removeClass("data-changed");
         }
       });
       $(this).unbind('change').bind('change', function(e) {
         $(this).addClass("data-changed");
         if ($(this).attr("id") == "embargo_embargo_release_date") {
           if ($(this).val().length == 10) {
             $(this).blur();
           }
         }
       });
     });
     return this;
   };
   
   /*
   * Initialize the element as a Hydra Editable TextileField (textile-processed textarea)
   */
   $.fn.hydraTextileField = function(settings) {
     var config = {
       method    : "PUT",
       indicator : "<img src='/plugin_assets/hydra-head/images/ajax-loader.gif'>",
       type      : "textarea",
       //submit    : "OK",
       //cancel    : "Cancel",
       placeholder : "<textarea></textarea>",
       tooltip   : "Click to edit ...",
       onblur    : "submit",
       id        : "field_id",
       height    : "100"
     };
 
     if (settings) $.extend(config, settings);
     
     this.each(function() {
      var $this = $(this);
      var $editNode = $(".textile-edit", this).first();  
      var $textNode = $(".textile-text", this).first();  
      var $closestForm =  $editNode.closest("form");
      var name = $editNode.attr("name");      
      
      // collect submit parameters.  These should probably be shoved into a data hash instead of a url string...
      // var field_param = $editNode.fieldSerialize();
      var field_selectors = $("input.fieldselector[rel="+$editNode.attr("rel")+"]").fieldSerialize();
      
      //Field Selectors are the only update params to be passed in the url
      var assetUrl = $closestForm.attr("action") + "&" + field_selectors;
      var submitUrl = $.fn.hydraMetadata.appendFormat(assetUrl, {format: "textile"});

      // These params are all you need to load the value from AssetsController.show
      // Note: the field value must match the field name in solr (minus the solr suffix)
      var load_params = {
        datastream  : $editNode.attr('data-datastream-name'),
        field       : $editNode.attr("rel")//,
        //field_index : $this.index()
      };
      
      var nodeSpecificSettings = {
        tooltip   : "Click to edit "+$this.attr("id")+" ...",
        name      : name,
        loadurl  : assetUrl + "?" + $.param(load_params)
      };

      $textNode.editable(submitUrl, $.extend(nodeSpecificSettings, config));
      $editNode.hide();
     });
      
     return this;
 
   };
   
   /*
   *  Initialize all Textile Fields within the given selector
   */
   $.fn.hydraTextileFields = function(settings) {
     var config = {'foo': 'bar'};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(".textile-container", this).hydraTextileField(config);
     });
 
     return this;
   };
   
   $.fn.hydraRadioButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
           $.fn.hydraMetadata.saveSelect(this, e);
           //e.preventDefault();
         });
     });
 
     return this;
 
   };

   $.fn.hydraCheckbox = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
         var checked = $(this).attr("checked");
         // temporarily uncheck it so it gets submitted
         if(!checked) {
           $(this).attr("checked",true);
         }
         // adding checks for yes and no attributes so that other values can be passed in
         checkbox_id = $(this).attr("id");

         if ($(this).val() == $("#"+checkbox_id+"_checked_value").val() ) {
           $(this).val($("#"+checkbox_id+"_unchecked_value").val() );
         } else {
           $(this).val($("#"+checkbox_id+"_checked_value").val() );
         }
         $.fn.hydraMetadata.saveCheckbox(this,e);
         if (!checked) {
           $(this).attr("checked",false);
         }
         //e.preventDefault();
       });
     });
 
     return this;
 
   };
  
   // 
   // This method relies on some options being saved in the dom element's data, which is populated by a little script inserted by the fedora_date_select helper.  
   // For example:
   //
   // $('div.date-select[name="asset[descMetadata][journal_0_issue_publication_date]"]').data("opts")
   // will return
   // {
   //   formElements: {
   //     journal_0_issue_publication_date-sel-dd: "d"
   //     journal_0_issue_publication_date-sel-mm: "m"
   //     journal_0_issue_publication_date-sel-y: "Y"
   //    }
   //  }
   //
   $.fn.hydraDatePicker = function(settings) {
      var config = {
       showWeeks    :   true,
       statusFormat :   "l-cc-sp-d-sp-F-sp-Y",
       callbackFunctions : {
         "dateset": [$.fn.hydraMetadata.saveDateWidgetEdit]
       }
      };

      if (settings) $.extend(config, settings);

      this.each(function() {
        var $this = $(this);
        var opts = $.extend($this.data("opts"), config);
        datePickerController.createDatePicker(opts);
      });
 
      return this;

   };
   
   /*
   *  Initialize all Permissions Sliders within the given selector
   */
   $.fn.hydraPermissionsSlider = function(settings) {
     var config = {
       labelSrc   : 'text',
       sliderOpts : {
		    change: function(event, ui) { 
          var associatedSelect = $(ui.handle).parent().prev();
          $.fn.hydraMetadata.updatePermission(associatedSelect);
          }
        }
		  };
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
 				$(this).selectToUISlider(config).hide();
     });
 
     return this;
 
   };
   
   /*
   *  Initialize the form for inserting new Person (individual) permissions
   */
   $.fn.hydraNewPermissionsForm = function(settings) {
     var config = { 
         clearForm: true,        // clear all form fields after successful submit 
         timeout:   2000,
         success:   $.fn.hydraMetadata.addPersonPermission  // post-submit callback 
     };
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).ajaxForm(config);
     });
 
     return this;
 
   };

   /*
   *  Initialize the form for inserting new Grant
   */
   $.fn.hydraNewGrantForm = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $("#.addval.grant").click(function(e) {
				$.fn.hydraMetadata.addGrant(this, e);
         e.preventDefault();
       });
     });
 
     return this;
 
   };
   
   
   /*
   *  Initialize the form for inserting new Person (individual) permissions
   *  ex. $("#add-contributor-box").hydraNewContributorForm
   */
   $.fn.hydraNewContributorForm = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $("#re-run-add-contributor-action", this).click(function() {
				 contributor_label = $(this).val().split(' ');
				 contributor_type = contributor_label[contributor_label.length-1];
				 if (contributor_type == "researcher") {contributor_type = "person";};
         $.fn.hydraMetadata.addContributor(contributor_type);
       });
       $("#add_author", this).click(function() {
         $.fn.hydraMetadata.addContributor("person");
       });
       $("#add_person", this).click(function() {
         $.fn.hydraMetadata.addContributor("person");
       });
       $("#add_organization", this).click(function() {
         $.fn.hydraMetadata.addContributor("organization");
       });
       $("#add_conference", this).click(function() {
         $.fn.hydraMetadata.addContributor("conference");
       });
     });
 
     return this;
 
   };
   
   $.fn.hydraAddTextFieldAddButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
           $.fn.hydraMetadata.insertTextField(this, e);
           e.preventDefault();
       });
      });
 
     return this;
 
   };
   
   
   $.fn.hydraTextileFieldAddButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
         $.fn.hydraMetadata.insertTextileField(this, e);
         e.preventDefault();
       });
     });
 
     return this;
 
   };
   
   $.fn.hydraFieldDeleteButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
         $.fn.hydraMetadata.deleteFieldValue(this, e);
         e.preventDefault();
       });
      });
 
     return this;
 
   };

   $.fn.hydraGrantDeleteButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
          $.fn.hydraMetadata.deleteGrant(this, e);
          e.preventDefault();
        });
     });
 
     return this;
 
   };


   
   $.fn.hydraContributorDeleteButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
          $.fn.hydraMetadata.deleteContributor(this, e);
          e.preventDefault();
        });
     });
 
     return this;
 
   };
   
   $.fn.hydraFileAssetDeleteButton = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('click.hydra').bind('click.hydra', function(e) {
           $.fn.hydraMetadata.deleteFileAsset(this, e);
           e.preventDefault();
         });
     });
 
     return this;
 
   };
   
 })(jQuery);


