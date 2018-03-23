Blacklight.onLoad(function() {
  // Create sortable, searchable table
  $('#analytics-collections-table').DataTable();
  $('#analytics-works-table').DataTable();

  // Transition between time periods or object type
  $('.admin-repo-charts').on('click', function (e) {
    var type_id = e.target.id;
    var field = $('#' + type_id);

    $(field).on('ajax:success', function (e, data) {
      var update_chart_id = (/days/.test(type_id)) ? 'dashboard-growth' : 'dashboard-repository-objects';
      updateChart(update_chart_id, data);

      var clicked_chart = field.parents().filter('ul').attr('id');
      $('#' + clicked_chart + ' a').removeClass('stats-selected');
      field.addClass('stats-selected');
    });
  });

  function updateChart(id, data) {
    var chart = Chartkick.charts[id];
    chart.updateData(data);
  }
});