//= require highcharts
//= require highcharts/highcharts-more
//= require highcharts/modules/drilldown

(function( $ ){
  $.fn.pie_chart = function(title, data) {
    // Create the chart
    $(this).highcharts({
        chart: {
            type: 'pie'
        },
        plotOptions: {
            series: {
                dataLabels: {
                    enabled: true,
                    format: '{point.name}: {point.y}'
                }
            }
        },

        credits: {
          enabled: false
        },

        tooltip: {
            headerFormat: '<span style="font-size:11px">{series.name}</span><br>',
            pointFormat: '<span style="color:{point.color}">{point.name}</span>: <b>{point.percentage:.2f}%</b> of total<br/>'
        },
        series: [{
            name: title,
            colorByPoint: true,
            data: data.series
        }],
        title: null,
        drilldown: data.drilldown
    });
  };
})( jQuery );

Blacklight.onLoad(function () {
    $('.stats-pie').each (function () {
      series = $(this).data('series');
      title = $(this).data('title');
      drilldown = $(this).data('drilldown');
      $(this).pie_chart(title, series, drilldown);
    });
});
