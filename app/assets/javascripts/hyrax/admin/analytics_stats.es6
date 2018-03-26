export default class {
  constructor() {
    this.collections_table = $('#analytics-collections-table');
    this.works_table = $('#analytics-works-table');
    this.admin_repo_charts = $('.admin-repo-charts');

    this.createDataTables();
    this.transitionChart();
  }

  createDataTables() {
    this.collections_table.DataTable();
    this.works_table.DataTable();
  }

  transitionChart() {
    this.admin_repo_charts.on('click', (e) => {
      let type_id = e.target.id;
      let field = $('#' + type_id);

      $(field).on('ajax:success', (e, data) => {
        let update_chart_id = (/days/.test(type_id)) ? 'dashboard-growth' : 'dashboard-repository-objects';
        this.updateChart(update_chart_id, data);

        let clicked_chart = field.parents().filter('ul').attr('id');
        $('#' + clicked_chart + ' a').removeClass('stats-selected');
        field.addClass('stats-selected');
      })
    });
  }

  updateChart(id, data) {
    let chart = Chartkick.charts[id];
    chart.updateData(data);
  }
}
