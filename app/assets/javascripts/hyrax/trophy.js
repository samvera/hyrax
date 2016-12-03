function toggleTrophy(url, anchor) {
  $.ajax({
     url: url,
     type: "post",
     success: function(data) {
       gid = data.work_id;
       if (anchor.hasClass("trophy-on")){
         // we've just removed the trophy
         trophyOff(anchor);
       } else {
         trophyOn(anchor);
       }

       anchor.toggleClass("trophy-on");
       anchor.toggleClass("trophy-off");
     }
  });
}
// Trophy will be removed
function trophyOff(anchor) {
    if (anchor.data('removerow')) {
        $('#trophyrow_'+gid).fadeOut(1000, function() {
            $('#trophyrow_'+gid).remove();
        });
    } else {
        setAnchorAttrs(anchor, 'Highlight work', 'add-text');
    }
}

function trophyOn(anchor) {
    setAnchorAttrs(anchor, 'Unhighlight work', 'remove-text');
}

function setAnchorAttrs(anchor, title, data) {
    anchor.attr('title', title);
    $nodes = anchor.contents();
    $nodes[$nodes.length - 1].nodeValue = anchor.data(data)
}

Blacklight.onLoad( function() {
  // #this method depends on a "current_user" global variable having been set.
  $('.trophy-class').click(function(evt){
    evt.preventDefault();
    anchor = $(this);
    toggleTrophy(anchor.data('url'), anchor);
  });
});
