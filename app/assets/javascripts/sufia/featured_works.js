Blacklight.onLoad(function() {
  $('a[data-behavior="feature"]').on('click', function(evt) {
    evt.preventDefault();
    anchor = $(this);
    $.ajax({
       url: anchor.attr('href'),
       type: "post",
       success: function(data) {
         anchor.before("Featured");
         anchor.remove();
       }
    });
  });

  $('a[data-behavior="unfeature"]').on('click', function(evt) {
    evt.preventDefault();
    anchor = $(this);
    $.ajax({
       url: anchor.attr('href'),
       type: "post",
       data: {"_method":"delete"}, 
       success: function(data) {
         row = anchor.closest('li')
         row.fadeOut(1000, function() {
           row.remove();
         });
       }
    });
  });
});
