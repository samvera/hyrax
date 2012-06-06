$(document).ready(function(){
	$(".loggedin").click(function(){
		$(this).next(".dropdown").slideToggle(400);
	});
	
	$(".itemexpand").click(function(){
		$(this).parent().parent().next("tr.hidden").toggle();
		$(this).toggleClass("itemexpand itemhide");
		return false;
	});
	
	$("h3.expandable").click(function(){
		$(this).next("ul").slideToggle();
		$(this).toggleClass("open");
	});

	$('#generic_file_permissions_new_group_name').change(function (){
        var edit_option = $("#generic_file_permissions_new_group_permission option[value='edit']")[0];
	    if (this.value.toUpperCase() == 'PUBLIC') {
	       edit_option.disabled =true;	       
	    } else {
           edit_option.disabled =false;         
	    }
	    
	});
});