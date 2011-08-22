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
});

// Define Hydra-Head methods for HydraHead object
(function($) {
  
  HydraHead.add_asset_links = function() {
    $('.create_asset').each(function() {
      $(this).attr('href', $(this).attr('href') + "&combined=true");
    });
  };
    
})(jQuery);