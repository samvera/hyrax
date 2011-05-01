// Uncomment this if you want fluid to provide log messages in the console.
// see <http://wiki.fluidproject.org/display/fluid/Framework+Functions#FrameworkFunctions-fluid.log%28str%29>
fluid.setLogging(true);

$(document).ready(function()
{
    //-------------------------------------------------------
    /*shows the loading div every time we have an Ajax call*/
    $("#loading").bind("ajaxSend", function(){
       $(this).show();
     }).bind("ajaxComplete", function(){
       $(this).hide();
   });
   //-------------------------------------------------------
})

jQuery(document).ready(function () {
    /* Example 3 - note the difference in the syntax */
    /* multiple inline edit requires each editable text object to be wrapped again inside another element */                
    var singleValueEdits = fluid.inlineEdits("#multipleEdit", {
        selectors : {
          text : ".editableText",
          editables : "li.editable"
        }, 
        listeners : {
          onFinishEdit : myFinishEditListener,
          modelChanged : myModelChangedListener
        },
        defaultViewText: "click to edit"
    });
    

    var richEdits = setupRichTextEdits($(".editable_textarea"), {
        // FCKEditor: {BasePath: "/plugin_assets/fluid-infusion/javascripts/../infusion/tests/manual-tests/lib/fckeditor/"},
        FCKEditor: {
          BasePath: "/javascripts/fckeditor/", 
          ToolbarSet: "Basic"
        },
        listeners : {
          onFinishEdit : myFinishEditListener,
          modelChanged : myModelChangedListener
        },
        defaultViewText: "click to edit"
    });
    
});

/**
 * Creates a whole list of Rich Text Editors editors.
 */
var setupRichTextEdits = function (editables, options) {
    var editors = [];    
    editables.each(function (idx, editable) {
        editors.push(fluid.inlineEdit.FCKEditor($(editable), options));
    });
    makeAllFluidSaveCancelButtons(editors);
    
    return editors;
};


/**
 * Create cancel and save buttons for a rich inline editor.
 * @param {Object} editor 
 */
var makeFluidSaveCancelButtons = function (editor) {
    $(".save", editor.container).click(function(event){
        event.preventDefault();
        editor.finish();
        return false;
    });

    $(".cancel", editor.container).click(function(event){
        event.preventDefault();
        editor.cancel();
        return false;
    });
};

/**
 * Create cancel and save buttons for all rich text editors.
 * @param {Object} editors array of rich inline editors.
 */
var makeAllFluidSaveCancelButtons = function (editors) {
    while (editors.length > 0) {
        makeFluidSaveCancelButtons(editors.pop());
    }
};

/***
 * Inserting and removing simple inline edits
 */
 
function insertValue(fieldName) {
  var values_list = jQuery("#salt_document_"+fieldName+"_values");
  var new_value_index = values_list.children('li').size()
  var unique_id = "salt_document_" + fieldName + "_" + new_value_index;
  
  var div = jQuery('<li class=\"editable\" id="'+unique_id+'" name="salt_document[' + fieldName + '][' + new_value_index + ']"><a href="javascript:void();" onClick="removeFieldValue(this);" class="destructive"><img src="/plugin_assets/hydra-head/images/delete.png" border="0" /></a><span class="flc-inlineEdit-text"></span></li>');
  div.appendTo(values_list); 
  var newVal = fluid.inlineEdit("#"+unique_id, {
    listeners : {
      onFinishEdit : myFinishEditListener,
      modelChanged : myModelChangedListener
    },
    defaultViewText: "click to edit"
  });
  newVal.edit();
}


/***
 * Inserting and removing rich inline edits
 */
 
 function insertTextAreaValue(fieldName) {
   var d = new Date(); // get milliseconds for unique identfier
   var unique_id = "salt_document_" + fieldName + "_" + d.getTime();
   // <div class="flc-inlineEdit-text">&nbsp;
   // </div>
   // <div class="flc-inlineEdit-editContainer">
   //     <textarea></textarea>
   //     <button class="save">Save</button> <button class="cancel">Cancel</button>
   // </div>
   var div = jQuery('<li class=\"editable_textarea\" id="'+unique_id+'" name="document[' + fieldName + '][-1]"><a href="javascript:void();" onClick="removeFieldValue(this);" class="destructive"><img src="/plugin_assets/hydra-head/images/delete.png" border="0" /></a><div class="flc-inlineEdit-text"></div><div class="flc-inlineEdit-editContainer"><textarea></textarea><button class="save">Save</button> <button class="cancel">Cancel</button></div> </dd>');
   div.appendTo("#salt_document_"+fieldName+"_values"); 
   //return false;

   var newVal = fluid.inlineEdit.FCKEditor("#"+unique_id, {
       // FCKEditor: {BasePath: "/plugin_assets/fluid-infusion/javascripts/../infusion/tests/manual-tests/lib/fckeditor/"},
        FCKEditor: {
          BasePath: "/javascripts/fckeditor/", 
          ToolbarSet: "Basic"
        },
        listeners : {
          onFinishEdit : myFinishEditListener,
          modelChanged : myModelChangedListener
        },
        defaultViewText: "click to edit"
    })
    makeFluidSaveCancelButtons(newVal)
    newVal.edit();

 }


/***
 * Handlers for when you're done editing and want values to submit to the app. 
 */

function myFinishEditListener(newValue, oldValue, editNode, viewNode) {
  // Only submit if the value has actually changed.
  if (newValue != oldValue) {
    var result = saveEdit($(viewNode).parent().attr("name"), newValue)
  }
  return result;
}

function saveModifiedField(element, value) {  
  result = saveEdit($(element).parent().attr("name"), value);
  // return value;
}

function saveEdit(field,value) {
  result = $.ajax({
    async: false,
    type: "PUT",
    url: $("form#document_metadata").attr("action"),
    dataType : "json",
    data: field+"="+value,
    success: function(msg){
       jQuery.noticeAdd({
        inEffect:               {opacity: 'show'},      // in effect
        inEffectDuration:       600,                    // in effect duration in miliseconds
        stayTime:               6000,                   // time in miliseconds before the item has to disappear
        text:                   "Your edit to "+ msg.updated[0].field_name +" has been saved as "+msg.updated[0].value+" at index "+msg.updated[0].index,   // content of the item
        stay:                   false,                  // should the notice item stay or not?
        type:                   'notice'                // could also be error, succes       
       });
       result = value;
    },
    error: function(xhr, textStatus, errorThrown){
       jQuery.noticeAdd({
        inEffect:               {opacity: 'show'},      // in effect
        inEffectDuration:       600,                    // in effect duration in miliseconds
        stayTime:               6000,                   // time in miliseconds before the item has to disappear
        text:                   'Your changes to' + field + ' could not be saved because of '+ xhr.statusText + ': '+ xhr.responseText,   // content of the item
        stay:                   true,                  // should the notice item stay or not?
        type:                   'error'                // could also be error, succes        
       });
       result = false;
    }
  });
}


/***
 * Handler for ensuring that the undo decorator's actions will be submitted to the app.
 */

function myModelChangedListener(model, oldModel, source) {
  // this was a really hacky way of checking if the model is being changed by the undo decorator
  if (source && source.options.selectors.undoControl) {  
    var result = saveEdit(source.component.editContainer.parent().attr("name"), model.value);
    return result;
  }
}
