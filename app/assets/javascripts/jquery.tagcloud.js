/*!
 * flyingzumwalt: jquery.tagcloud.js v. 0.1.0
 *    (contains modifications for use in projecthydra/sufia)
 *
 * Forked from:
 *
 * jquery.tagcloud.js
 * A Simple Tag Cloud Plugin for JQuery
 *
 * https://github.com/addywaddy/jquery.tagcloud.js
 * created by Adam Groves
 */
(function($) {

  /*global jQuery*/
  "use strict";

  var compareWeights = function(a, b)
  {
    return a - b;
  };

  // Converts hex to an RGB array
  var toRGB = function(code) {
    if (code.length === 4) {
      code = code.replace(/(\w)(\w)(\w)/gi, "\$1\$1\$2\$2\$3\$3");
    }
    var hex = /(\w{2})(\w{2})(\w{2})/.exec(code);
    return [parseInt(hex[1], 16), parseInt(hex[2], 16), parseInt(hex[3], 16)];
  };

  // Converts an RGB array to hex
  var toHex = function(ary) {
    return "#" + jQuery.map(ary, function(i) {
      var hex =  i.toString(16);
      hex = (hex.length === 1) ? "0" + hex : hex;
      return hex;
    }).join("");
  };

  var colorIncrement = function(color, range) {
    return jQuery.map(toRGB(color.end), function(n, i) {
      return (n - toRGB(color.start)[i])/range;
    });
  };

  var tagColor = function(color, increment, weighting) {
    var rgb = jQuery.map(toRGB(color.start), function(n, i) {
      var ref = Math.round(n + (increment[i] * weighting));
      if (ref > 255) {
        ref = 255;
      } else {
        if (ref < 0) {
          ref = 0;
        }
      }
      return ref;
    });
    return toHex(rgb);
  };
  
  // Scales the value according to the preferred granularity based on the max value for the scale
  // Assumes an inverted scale, where 1 corresponds to the highest values.
  // This is useful for generating css styles corresponding to scaled values 
  //    (ie. weight-1 for largest values, weight-15 for smallest values)
  // Examples: 
  //    scaleValue(322,322,15)  => 1
  //    scaleValue(250,322,15)  => 4
  //    scaleValue(75,322,15)   => 12
  //    scaleValue(5,322,15)    => 15
  //    scaleValue(2,322,15)    => 15
  var scaleValue = function(value, max, granularity) {
    var scaleFactor = ((granularity-1)/max)
    return granularity - Math.round(value*scaleFactor) 
  }

  $.fn.tagcloud = function(options) {

    var opts = $.extend({}, $.fn.tagcloud.defaults, options);
    var tagWeights = this.children().map(function(idx, item){
      return $(item).attr("rel")
    });
    tagWeights = jQuery.makeArray(tagWeights).sort(compareWeights);
    var lowest = tagWeights[0];
    var highest = tagWeights.pop();
    var range = highest - lowest;
    if(range === 0) {range = 1;}
    // Sizes
    var fontIncr, colorIncr;
    if (opts.size) {
      fontIncr = (opts.size.end - opts.size.start)/range;
    }
    // Colors
    if (opts.color) {
      colorIncr = colorIncrement (opts.color, range);
    }
    return this.children().each(function() {
      var weighting = $(this).attr("rel") - lowest;
      if (opts.size) {
        $(this).css({"font-size": opts.size.start + (weighting * fontIncr) + opts.size.unit});
      }
      if (opts.color) {
        $(this).css({"color": tagColor(opts.color, colorIncr, weighting)});
      }
      if (opts.cssHooks) {
        $(this).addClass("weight-"+scaleValue($(this).attr("rel"), highest, opts.cssHooks.granularity))
      }
    });
  };

  $.fn.tagcloud.defaults = {
    // size: {start: 0.9, end: 2.5, unit: "em"},
    cssHooks: {granularity: 15}
  };

})(jQuery);