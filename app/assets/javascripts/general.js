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
});