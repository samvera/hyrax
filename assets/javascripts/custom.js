function async_load(url, divid) {
  $.ajax({
    type: "GET",
    url: url,
    dataType: "html",
    success: function(data){
            $(divid).html(data);
            $("#file_assets  .editable-container").hydraTextField();
            $("#file_assets  a.destroy_file_asset").hydraFileAssetDeleteButton();
            // Custom for Libra -- update progress box when necessary
            $.fn.hydraProgressBox.testReleaseReadiness();
            var stepOneReady = $.fn.hydraProgressBox.testStepOneReadiness();
            $.fn.hydraProgressBox.checkUncheckProgress('step_1_label', stepOneReady);
          }
  });
  // $(divid).load(url);
  return null;
}

var Hydrangea = {};

Hydrangea.FileUploader = function() {
  var pid = null;

  return {
    setUp: function() {
      //TODO: DRY this up.
      $("a#toggle-uploader").live('click', Hydrangea.FileUploader.toggle);
      $("a#toggle-uploader-generic").live('click', Hydrangea.FileUploader.toggleGeneric);
      pid = $("div#uploads").attr("data-pid");
      async_load("/assets/" + pid + "/file_assets/new", "div#uploader");
    },
    toggle: function() {
      if ($("a#toggle-uploader").html().trim() === "Upload files") {
        $("a#toggle-uploader").html("Hide file uploader");
        async_load("/assets/" + pid + "/file_assets/new", "div#uploader");
      } else {
        $("a#toggle-uploader").html("Upload files");
        $("div#uploader").html("");
      }
      return false;
    },
    toggleGeneric: function() {
      if ($("a#toggle-uploader-generic").html().trim() === "Upload file") {
        $("a#toggle-uploader-generic").html("Hide file uploader");
        $("form.fl-progEnhance-enhanced").show();
      } else {
        $("a#toggle-uploader-generic").html("Upload file");
        $("form.fl-progEnhance-enhanced").hide();
      }
      return false;
    }
  };
}();

// Document Ready
jQuery(document).ready(function($) {
	// Accordion Behavior
	$("#accordion").accordion({
	    autoHeight: false,
	    clearStyle: false,
	    collapsible: false,
	    active: 0,
	    icons: false,
			fillSpace: true	
	});	
	$(function() {
			$("#accordion").resizable({
				minHeight: 140,
				resize: function() {
					$( "#accordion" ).accordion( "resize" );
				}
			});
		});
	
	// CHANGE LABELS TO BE CONSISTENT FOR UVA
	$("#keywords_fieldset a.addval").text('Add Keyword');
	
	// FORCE FLUID INFUSION TEXT FIELDS TO A MINIMUM LENGTH
	$('input.editable-edit').css('min-width', '150px');
	$('dd.citation ul input.editable-edit.edit').css('min-width', '40px');

  //update the progress box checks
  $("div.step_label.progressItem.progressItemChecked").css("background-image",'url(/images/chkbox_checked.png)');
	
	// REDUCE MARGIN-TOP FOR FIRST <h2>
	$('h2:first').css('margin-top', '0');
	
	// REDUCE MARGIN-TOP FOR FIRST <h2>
	$('h2:first').css('margin-top', '0');		
	
	// HIDE THE INPLACE EDIT FIELDS
	$('span.editable-text.text').hide();
	
	// SHOW THE INPLACE TEXTILE FIELDS
	$('input.textile-edit.edit').css('display', 'block');
	
	// ADD THE DATEPICKER CLASS TO _DATE FIELDS
	//	<input type="text" class="datepicker" size="30" name="d1" value="" placeholder="YYYY-MM-DD"/>
	$('input[name*=_date]').addClass('datepicker');
	// fluid.defaults('inlineEdit').blurHandlerBinder = function(that) {
	// 	// This is just fluid's normal default handling of a blur event:
	// 	that.editField.blur(
	// 		function (evt) {
	// 			if (that.isEditing())
	// 				that.finish();
	// 			return false;
	// 		}
	// 	);
		
		// InlineEdit doesn't watch for change events on the input field, which means that it doesn't
		// pick up a new date from the datepicker. We fix this by adding a change observer which fires
		// the same update of the Fluid model that a blur event does.
	// 	that.editField.change(
	// 		function (evt) {
	// 			if (!that.isEditing() && that.editView.value != that.model.value)
	// 				that.finish();
	// 			return true;
	// 		}
	// 	)
	// }
	
  $('a#delete_asset_link').click(
      function () {
        pid = $("div#uploads").attr("data-pid");
        url = '/assets/'+pid+'/file_assets?deletable=true&layout=false';
        $.ajax({
          type: "GET",
          url: url,
          dataType: "html",
          success: function(data){
                  $('div#deletable_assets').html(data);
                  $("div#delete_dialog").parent().show();
                }
        });
      }
  );

});
