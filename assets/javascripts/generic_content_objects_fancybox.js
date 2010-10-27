$(document).ready(function() {

	/* This is basic - uses default settings */
	$("a.fbImage").fancybox( {
		'type' : 'image'
	});
	$("a.fbContent").fancybox( {
		'type' : 'ajax'
	})
	$("a.fbIframe").fancybox( {
		'type' : 'iframe'
	})
	
});