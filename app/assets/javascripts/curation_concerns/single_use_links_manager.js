(function( $ ){
  $.fn.singleUseLinks = function( options ) {

    var clipboard = new Clipboard('.copy-single-use-link');

    var manager = {
      reload_table: function() {
        var url = $("table.single-use-links tbody").data('url')
        $.get(url).done(function(data) {
          $('table.single-use-links tbody').html(data);
        });
      },

      create_link: function(caller) {
        $.post(caller.attr('href')).done(function(data) {
          manager.reload_table()
        })
      },

      delete_link: function(caller) {
        $.ajax({
          url: caller.attr('href'),
          type: 'DELETE',
          done: caller.parent('td').parent('tr').remove()
        })
      }
    };

    $('.generate-single-use-link').click(function(event) {
      event.preventDefault()
      manager.create_link($(this))
      return false
    });

    $("table.single-use-links tbody").on('click', '.delete-single-use-link', function(event) {
      event.preventDefault()
      manager.delete_link($(this))
      return false;
    });

    clipboard.on('success', function(e) {
      $(e.trigger).tooltip('show');
      e.clearSelection();
    }); 

    return manager;

  };
})( jQuery );

Blacklight.onLoad(function () {
  $('.single-use-links').singleUseLinks();
});
