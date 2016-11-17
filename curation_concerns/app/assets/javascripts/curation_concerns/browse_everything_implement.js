$(document).on('page:change', function() {
	$('#browse').browseEverything()
			.done(function(data) {
				$('#status').html(data.length.toString() + " items selected")
			})
			.cancel(function()   { window.alert('Canceled!') });
});