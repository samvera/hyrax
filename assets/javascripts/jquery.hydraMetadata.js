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

       var $item = $('<li class=\"editable-container field\" id="'+unique_id+'-container"><a href="" class="destructive field" title="Delete \'[NAME OF THING] in hydraMetadata.insertTextField\'">Delete</a><span class="editable-text" id="'+unique_id+'-text"></span><input class="editable-edit" id="'+unique_id+'" data-datastream-name="'+datastreamName+'" rel="'+fieldName+'" name="asset['+datastreamName+'][' + fieldName + '][' + new_value_index + ']"/></li>');
       $item.appendTo(values_list);
       var newVal = fluid.inlineEdit($item, {
                     selectors: {
                       editables : ".editable-container",
                       text : ".editable-text",
                       edit: ".editable-edit"
                     },
                     componentDecorators: {
                       type: "fluid.undoDecorator"
                     },
                     listeners : {
                       onFinishEdit : jQuery.fn.hydraMetadata.fluidFinishEditListener,
                       modelChanged : jQuery.fn.hydraMetadata.fluidModelChangedListener
                     }
                   });
                   newVal.edit();
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

       var $item = jQuery('<li class=\"field_value textile_value\" name="asset[' + fieldName + '][' + new_value_index + ']"><a href="" class="destructive"><img src="/plugin_assets/hydra_repository/images/delete.png" border="0" /></a><div class="textile" id="'+fieldName+'_'+new_value_index+'">click to edit</div></li>');
       $item.appendTo(values_list);

       $("div.textile", $item).editable(assetUrl+"&format=textile", {
           method    : "PUT",
           indicator : "<img src='/plugin_assets/hydra_repository/images/ajax-loader.gif'>",
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
         $(contributors_group_selector).last().after(data);
         $inserted = $(contributors_group_selector).last();
         $(".editable-container", $inserted).hydraTextField();
         $("a.destructive", $inserted).hydraContributorDeleteButton();
				$("#re-run-add-contributor-action").val("Add a " + type);
       });
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
     var config = {
        selectors : {
          text  : ".editable-text",
          edit  : ".editable-edit"           
        },
        componentDecorators: {
          type  : "fluid.undoDecorator"
        },
        listeners : {
          onFinishEdit : jQuery.fn.hydraMetadata.fluidFinishEditListener,
          modelChanged : jQuery.fn.hydraMetadata.fluidModelChangedListener
        },
        defaultViewText: "click to edit"
      };
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       fluid.inlineEdit(this, config);
     });
 
     return this;
 
   };
   
   /*
   * Initialize the element as a Hydra Editable TextileField (textile-processed textarea)
   */
   $.fn.hydraTextileField = function(settings) {
     var config = {
       method    : "PUT",
       indicator : "<img src='/plugin_assets/hydra_repository/images/ajax-loader.gif'>",
       type      : "textarea",
       submit    : "OK",
       cancel    : "Cancel",
       placeholder : "click to edit",
       tooltip   : "Click to edit ...",
       onblur    : "ignore",
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
        field       : $editNode.attr("rel"),
        field_index : $this.index()
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


   $.fn.hydraSelectMenu = function(settings) {
     var config = {};
 
     if (settings) $.extend(config, settings);
 
     this.each(function() {
       $(this).unbind('change.hydra').bind('change.hydra', function(e) {
           $.fn.hydraMetadata.saveSelect(this, e);
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
