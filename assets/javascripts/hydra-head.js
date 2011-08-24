/* Eliminate JavaScript functionality provided by Blacklight */
Blacklight.do_zebra_stripe = function(){};  

Blacklight.do_select_submit = function(){};

Blacklight.do_more_facets_behavior = function(){};

Blacklight.do_lightbox_dialog = function(){};

Blacklight.do_bookmark_toggle_behavior = function(){};

Blacklight.do_folder_toggle_behavior = function(){};       

Blacklight.do_facet_expand_contract_behavior = function(){};

HydraHead = {};

// Load appropriate Hydra-Head functions when document is ready
$(document).ready(function() {
  HydraHead.add_asset_links();
  HydraHead.enable_form_save();
});

// Define Hydra-Head methods for HydraHead object
(function($) {
  
  // Take Javascript-enabled users to the combined view
  HydraHead.add_asset_links = function() {
    $('.create_asset').each(function() {
      $(this).attr('href', $(this).attr('href') + "&combined=true");
    });
  };
  
  // Enable Ajax save functionality on edit pages
  HydraHead.enable_form_save = function() {
    HydraHead.target = null;
    var all_forms = $('.document_edit form');
    $('input[type="submit"]').click(function() {
      HydraHead.target = $(this);
    });
    all_forms.submit(function(e) {
      // Only submit the forms if they pass validation
      if(formValidation()){
        all_forms.each(function(index) {
          $(this).ajaxSubmit();
        });
        formRedirect(); 
      }
      return false;
    });
    
  };
  
  // Redirect the edit page after the user saves
  formRedirect = function() {
    
    // Wait for all saving calls to finish
    $("#document").ajaxStop(function(){
      var redirect_url = window.location.pathname + "?saved=true";
      
      // Add parameter if we're adding files
      if($('#number_of_files option:selected').length) {
        redirect_url += "&number_of_files=" + $('#number_of_files option:selected').val();
      }
      
      // Add parameter if we're adding a contributor
      if(HydraHead.target.attr("name") == "add_another_author") {
        redirect_url += "&add_contributor=true";
      }
      
      window.location = redirect_url;
    });
    
  };
  
  // Ensure all fields with an attribute of "required" have some value  
  formValidation = function() {
    // Input is innocent until proven guilty
    var valid = true;
    
    // Remove any existing notices
    $('#invalid_notice').remove();
    $('input[required]').removeClass("invalid-input");
    $('.invalid-input-notice').remove();
    
    // Check each input's value, switching the flag and appending a
    // notice if blank.
    $('input[required]').each(function(index) {
      if(!$(this).val()) {
        valid = false;
        $(this).addClass("invalid-input").after('<span class="invalid-input-notice">This field is required.</span>');
      }
    });
    
    // Add a top-level message if there are any invalid fields, and scroll there
    if(!valid) {
      $('#document h1').after('<div id="invalid_notice" class="error ui-state-error">Some required fields are incomplete.</div>');
      var new_position = $('#invalid_notice').offset();
      window.scrollTo(new_position.left, new_position.top - 40);
    }
    
    return valid;
  };
    
})(jQuery);