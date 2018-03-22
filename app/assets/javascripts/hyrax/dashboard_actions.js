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
  
  /**** Private functions ****/

  /**
   *  Shows details of expanded item
   * @param item
   */
  function show_details(item) {
    var array = item.id.split("expand_");
    if (array.length > 1) {
      var docId = array[1];
      $("#detail_" + docId + " .expanded-details").slideToggle();
      $(item).toggleClass('glyphicon-chevron-right glyphicon-chevron-down');
    }
  }

  // Create sortable, searchable collections table
  var collections_table = '#analytics-collections-table';
  var collections = createDataTable(collections_table);

  // Pin a collection
  $(collections_table).on('click', function(e) {
    var target = $('#' + e.target.id);
    var pinned = !target.hasClass('pinned');

    target.toggleClass('pinned', pinned);
    target.toggleClass('not-pinned', !target.hasClass('not-pinned'));

    // Update pinned status in the db
    $.ajax({
      method: 'POST',
      url: '/dashboard/pin_collection',
      data: { status: pinned, collection: target.attr('data-collection') }
    }).done(function(data) {

    });
  });

  // Create sortable, searchable works table
  var works = createDataTable('#analytics-works-table');

  // Destroy existing dataTables or Turbolinks keeps adding them to the page
  // when user hits back/forward buttons
  $(document).on('turbolinks:before-cache', function() {
    works.destroy();
    collections.destroy();
  });

  // Transition between time periods or object type for admin charts
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

  function createDataTable(selector, options) {
    if (options === undefined) {
      options = {};
    }
    options['responsive'] = true;
    return $(selector).DataTable(options);
  }

  function updateChart(id, data) {
    var chart = Chartkick.charts[id];
    chart.updateData(data);
  }
});
