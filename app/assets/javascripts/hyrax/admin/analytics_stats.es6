export default class {
  constructor() {
    this.collections_table = $('#analytics-collections-table');
    this.collections_table_body = $('#analytics-collections-table tbody');
    this.works_table = $('#analytics-works-table');
    this.admin_repo_charts = $('.admin-repo-charts');

    this.createDataTables();
    this.getPinnedCollections();
    this.pinCollection();
    this.transitionChart();
  }

  createDataTables() {
    let analytics_collections = this.collections_table.DataTable({ responsive: true });

    // Uses server side sorting, etc. Generally there will be way too many works to show them in one go
    let analytics_works = this.works_table.DataTable({
      ajax: {
        url: '/analytics/update_works_list',
        error: function (jqXHR, textStatus, errorThrown) {
          alert(errorThrown);
        }
      },
      language: {
        processing: '<img src="/assets/sm-loader.gif">'
      },
      search: {
        search: (val) => {
          if (val >= 3) {
            return  val;
          }

          return '';
        }
      },
      searchDelay: 350,
      processing: true,
      serverSide: true,
      responsive: true
    });

    this.minTableSearchLength('analytics-works-table', analytics_works);
    this.preventDuplicateTables(analytics_collections, analytics_works);
  }

  getPinnedCollections() {
    $.ajax({
      method: 'GET',
      url: '/analytics/all_pinned_collections',
      data: { user_id: $('#pinned-0').attr('data-user_id') }
    }).done((data) => {
      data.forEach((d) => {
        let selector = $("path[data-collection='" + d.collection + "']");

        selector.removeClass('not-pinned')
          .addClass('pinned');

        // Set correct sort ordering for pinned collections
        selector.closest('td')
          .attr('data-order', `1-${d.collection}`);
      });
    }).fail((jqXHR, textStatus) => {
      console.log(`Request failed: ${textStatus}. Unable to retrieve pinned collections`);
    });
  }

  pinCollection() {
    this.collections_table_body.on('click', (e) => {
      let target = $('#' + e.target.id);
      let pinned = !target.hasClass('pinned');
      let is_pinned = (pinned) ? 1 : 0;

      target.toggleClass('pinned', pinned);
      target.toggleClass('not-pinned', !target.hasClass('not-pinned'));

      // Update pinned status in the db
      $.ajax({
        method: 'POST',
        url: '/analytics/pin_collection',
        data: { status: is_pinned, user_id: target.attr('data-user_id'), collection: target.attr('data-collection') }
      }).done((data) => {
        target.text('Unpin Collection')
      }).fail((jqXHR, textStatus) => {
        console.log(`Request failed: ${textStatus}. Unable to update collection`);
      });
    });
  }

  /**
   * Add minimum typeahead length for dataTable filter searching
   * See https://stackoverflow.com/questions/5548893/jquery-datatables-delay-search-until-3-characters-been-typed-or-a-button-clicke/23897722#23897722
   * @param selector
   * @param table_obj
   */
  minTableSearchLength(selector, table_obj) {
    $('#' + selector + '_filter input')
      .unbind()
      .bind('input', function(e) {
        let search_value = this.value;

        if (search_value.length >= 3) {
          table_obj.search(search_value).draw();
        }

        if(search_value === '') {
          table_obj.search('').draw();
        }
      });
  }

  /**
   * Destroy existing dataTables or Turbolinks keeps adding them to the page
   * when user hits back/forward buttons
   * @param collections
   * @param works
   */
  preventDuplicateTables(collections, works) {
    $(document).on('turbolinks:before-cache', function() {
      collections.destroy();
      works.destroy();
    });
  }

  /**
   * Update CSS for clicked charts toggling
   */
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

  /**
   * Update a chart based on the clicked parameter
   * @param id
   * @param data
   */
  updateChart(id, data) {
    let chart = Chartkick.charts[id];
    chart.updateData(data);
  }
}
