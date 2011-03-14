// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery(document).ready(function($) {
	// ACTIVATE THE HOVER STATES OF THE IMAGE LINKS
	$(".libra_buttons img, .home_buttons img").hover(function(){
		$(this).siblings('ul').show();
		
	});
	
	$(".libra_buttons ul, .home_buttons ul").mouseleave(function(){
		$(this).hide();
	});
	
});


$(function() {
	// for create asset button at the top
  $("#re-run-action").next().button( {
    text: false,
    icons: { primary: "ui-icon-triangle-1-s" }
  })
  .click(function() {
    $('#create-asset-menu').is(":hidden") ? 
      $('#create-asset-menu').show() : $('#create-asset-menu').hide();
    })
  .parent().buttonset();
	
	if ($('#content_type').val()) {
		the_selected_content_type = $('#content_type').val();
		the_selected_content_type_label = $('#create-asset-menu li[onclick*="' + the_selected_content_type + '"]').html();
		$("#re-run-action").val(the_selected_content_type_label);
		//$('#re-run-action')[0].onclick = function(){ location.href='/assets/new?content_type=' + the_selected_content_type; };		
	}
	
	
  
  $('#create-asset-menu').mouseleave(function(){
    $('#create-asset-menu').hide();
  });

  // for add contributor (in edit article/dataset)
  $("#re-run-add-contributor-action").next().button( {
    text: false,
    icons: { primary: "ui-icon-triangle-1-s" }
  })
  .click(function() {
    $('#add-contributor-menu').is(":hidden") ? 
      $('#add-contributor-menu').show() : $('#add-contributor-menu').hide();
    })
  .parent().buttonset();
  
  $('#add-contributor-menu').mouseleave(function(){
    $('#add-contributor-menu').hide();
  });
});

function createAssetNavigateTo(elem, link) {
  $('#re-run-action')
  .attr('value', $(elem).text())
  .click(function() {
    $('#create-asset-menu').hide();
    location.href = link;
  });

  location.href = link;
}
