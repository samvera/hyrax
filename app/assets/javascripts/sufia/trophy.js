function toggleTrophy(url, anchor) {
  $.ajax({
     url: url,
     type: "post",
     success: function(data) {
       gid = data.generic_file_id;
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
    anchor.attr("title", "Highlight work");
    $nodes = anchor.contents()
    $nodes[$nodes.length - 1].nodeValue = anchor.data('add-text')
  }
}

function trophyOn(anchor) {
  anchor.attr("title", "Unhighlight work");
  $nodes = anchor.contents()
  $nodes[$nodes.length - 1].nodeValue = anchor.data('remove-text')
}

Blacklight.onLoad( function() {
  // #this method depends on a "current_user" global variable having been set.
  $('.trophy-class').click(function(evt){
    evt.preventDefault();
    anchor = $(this);
    toggleTrophy(anchor.data('url'), anchor);
  });
});


