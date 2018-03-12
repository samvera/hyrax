Blacklight.onLoad(function() {
  // toggle button on or off based on boxes being clicked
  $(".batch_document_selector, .batch_document_selector_all").bind('click', function(e) {
    var n = $(".batch_document_selector:checked").length;
    if (n>0 || ($('input#check_all').length && $('input#check_all')[0].checked)) {
      $('.sort-toggle').hide();
    } else {
      $('.sort-toggle').show();
    }
  });

  function show_details(item) {
    var array = item.id.split("expand_");
    if (array.length > 1) {
      var docId = array[1];
      $("#detail_" + docId + " .expanded-details").slideToggle();
      $(item).toggleClass('glyphicon-chevron-right glyphicon-chevron-down');
    }
  }

  // show/hide more information on the dashboard when clicking
  // plus/minus
  $('.glyphicon-chevron-right').on('click', function() {
    show_details(this);
    return false;
  });

  $('a').filter( function() {
      return $(this).find('.glyphicon-chevron-right').length === 1;
   }).on('click', function() {
    show_details($(this).find(".glyphicon-chevron-right")[0]);
    return false;
  });

  // Create sortable, searchable tables
  $('#analytics-collections-table').DataTable();

  // Uses server side sorting, etc. Generally there will be way too many works to show them in one go
  $('#analytics-works-table').DataTable({
    ajax: {
      url: '/dashboard/update_works_list',
      error: function (jqXHR, textStatus, errorThrown) {
        alert(errorThrown);
      }
    },
    language: {
      processing: '<img src="/assets/sm-loader.gif">'
    },
    processing: true,
    serverSide: true
  });

  // Transition between time periods or object type
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

  // Update chartkick graphs with new data
  function updateChart(id, data) {
    var chart = Chartkick.charts[id];
    chart.updateData(data);
  }
});
