function getSingleUse(item, fn) {
  console.log(item)
  var url = $(item).data('generate-single-use-link-url');
  if (!url) {
    alert("No url was provided for generating a single use link");
    return;
  }
  
  $.ajax({
    type: 'post',
    url: url,
    success: fn
	});
}

// A Turbolinks-enabled link has been clicked 
document.addEventListener("page:before-change", function(){
  ZeroClipboard.destroy();
});

Blacklight.onLoad(function() {
  $.each($(".copypaste"), function(idx, item) {
    var clip = new ZeroClipboard(this);

    clip.on("dataRequested", function(client, args) {
      getSingleUse(item, function(data) { 
        client.setText(data)
      });
    });

    clip.on("complete", function(client, args) {
      alert("A single use link to " + args.text + " was copied to your clipboard.");
    });
  });
});
