function async_load(url, divid) {
  $.ajax({
    type: "GET",
    url: url,
    dataType: "html",
    success: function(data){
            $(divid).html(data);
            $("#file_assets  .select-edit").hydraSelectMenu();
            $("#file_assets  .editable-container").hydraTextField();
            $("#file_assets  a.destroy_file_asset").hydraFileAssetDeleteButton();
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
	
	
	// FORM BEHAVIOR	
	if ( $("input:radio").filter("[value=completed]").attr("checked", false) && $("input:radio").filter("[value=ongoing]").attr("checked",false)) {
		$("input:radio").filter("[value=completed]").attr("checked","checked");
	}
	
	$("input:radio").change(function() {
		if ($(this + ':checked').val() == "ongoing" ) {
			$(".timespan_end label").text('Latest Date/Time');
		} else {
			$(".timespan_end label").text('End Date/Time');
		}
	});
	
	if ( $("input:radio").filter("[value=publicdomain]").attr("checked", false) && $("input:radio").filter("[value=odc-by]").attr("checked",false) && $("input:radio").filter("[value=odc-odbl]").attr("checked",false)) {
		$("input:radio").filter("[value=publicdomain]").attr("checked","checked");
	}
	
	// ADD THE DATEPICKER CLASS TO _DATE FIELDS
	//	<input type="text" class="datepicker" size="30" name="d1" value="" placeholder="YYYY-MM-DD"/>
	$('input[name*=_date]').addClass('datepicker');
	fluid.defaults('inlineEdit').blurHandlerBinder = function(that) {
		// This is just fluid's normal default handling of a blur event:
		that.editField.blur(
			function (evt) {
				if (that.isEditing())
					that.finish();
				return false;
			}
		);
		
		// InlineEdit doesn't watch for change events on the input field, which means that it doesn't
		// pick up a new date from the datepicker. We fix this by adding a change observer which fires
		// the same update of the Fluid model that a blur event does.
		that.editField.change(
			function (evt) {
				if (!that.isEditing() && that.editView.value != that.model.value)
					that.finish();
				return true;
			}
		)
	}
	
		
});
