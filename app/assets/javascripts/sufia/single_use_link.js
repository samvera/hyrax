function getSingleUse(item) {
  var url = $(item).data('generate_single_use_link_url');
  var rurl = window.location.protocol+"//"+window.location.host;
  var resp = $.ajax({
    headers: { Accept: "application/javascript" },
    type: 'get',
    url: url,
    async: false
	});
	return rurl  + resp.responseText;
}

Blacklight.onLoad(function() {
  $.each($(".copypaste"), function(idx, item) {
    var clip = new ZeroClipboard(this);

    clip.on("copy", function(client, args) {
      clip.setText(getSingleUse(item));
    });

    clip.on("aftercopy", function(client, args) {
      alert("A single use link to " + args.text + " was copied to your clipboard.");
    });

    clip.on("error", function(client, args) {
      alert("Your single-use link (please copy): " + getSingleUse(item));
    });
  });
});
