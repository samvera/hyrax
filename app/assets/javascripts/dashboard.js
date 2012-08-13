//= require jquery.zclip.min

/* polling functionality for the dashboard activity, can be turned on

setInterval(function() {
  var last_event_container = $('#last-event');
  var last_event = last_event_container.text();
  $.ajax({ url: "/dashboard/activity?since=" + last_event, success: function(data) {
    var new_timestamp = null;
    // Update activity stream on dashboard
    $.each(data, function(index, value) {
      var event = value[0];
      var when = value[1];
      var timestamp = value[2];
      $('#activity > tbody').prepend('<tr><td>&nbsp;</td><td>' + event + '</td><td>' + when + '</td></tr>');
      new_timestamp = timestamp;
    });
    if (new_timestamp !== null) {
      last_event_container.text(new_timestamp);
    };
  }, dataType: "json"});
}, 5000);

 */
