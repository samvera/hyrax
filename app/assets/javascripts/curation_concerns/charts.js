//= require jquery.flot
//= require jquery.flot.pie
//= require jquery.flot.resize

(function( $ ){
  $.fn.doughnut_chart = function( data ) {
    $.plot(this, data,
         {
           series: {
             pie: {
               innerRadius: 0.5,
               show: true,
               radius: 1,
               label: {
                 show: true,
                 radius: 3/4,
                 formatter: labelFormatter,
                 background: {
                   opacity: 0.5,
                   color: '#000'
                 }
               }
             }
           },
           legend: {
             show: false
           },
           grid: {
             hoverable: true
           }
         }
        );

    function labelFormatter(label, series) {
      return "<div style='font-size:8pt; text-align:center; padding:2px; color:white;'>" + label + "<br/>" + Math.round(series.percent) + "%</div>";
    }
  };
})( jQuery );

Blacklight.onLoad(function () {
    $('.stats-doughnut').each (function () {
      data = $(this).data('flot');
      $(this).doughnut_chart(data);
    });
});
