/*
Copyright © 2012 The Pennsylvania State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
