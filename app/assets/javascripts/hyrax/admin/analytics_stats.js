Blacklight.onLoad(function() {
  // Create sortable, searchable collections table
  $('#analytics-collections-table').DataTable();

  // Create sortable, searchable works table
  // Uses server side sorting, etc. Generally there will be way too many works to show them in one go
  var analytics_works = $('#analytics-works-table').DataTable({
    ajax: {
      url: '/dashboard/update_works_list',
      error: function (jqXHR, textStatus, errorThrown) {
        alert(errorThrown);
      }
    },
    language: {
      processing: '<img src="/assets/sm-loader.gif">'
    },
    search: {
      search: function(val) {
        if (val >= 3) {
          return  val;
        }

        return '';
      }
    },
    searchDelay: 350,
    processing: true,
    serverSide: true
  });

  minTableSearchLength('analytics-works-table');

  // Transition between time periods or object type for chartkick charts
  $('.admin-repo-charts').on('click', function(e) {
    var type_id = e.target.id;
    var field = $('#' + type_id);

    $(field).on('ajax:success', function(e, data) {
      var update_chart_id = (/days/.test(type_id)) ? 'dashboard-growth' : 'dashboard-repository-objects';
      updateChart(update_chart_id, data);

      var clicked_chart = field.parents().filter('ul').attr('id');
      $('#' + clicked_chart + ' a').removeClass('stats-selected');
      field.addClass('stats-selected');
    });
  });

  /**** Private functions ****/
  
  /**
   * Update chartkick graphs with new data
   * @param id
   * @param data
   */
  function updateChart(id, data) {
    var chart = Chartkick.charts[id];
    chart.updateData(data);
  }

  /**
   * Add minimum typeahead length for dataTable filter searching
   * See https://stackoverflow.com/questions/5548893/jquery-datatables-delay-search-until-3-characters-been-typed-or-a-button-clicke/23897722#23897722
   * @param selector
   */
  function minTableSearchLength(selector) {
    $('#' + selector + '_filter input')
      .unbind()
      .bind('input', function(e){
        var search_value = this.value;

        if (search_value.length >= 3) {
          analytics_works.search(search_value).draw();
        }

        if(search_value === '') {
          analytics_works.search('').draw();
        }
      });
  }
});