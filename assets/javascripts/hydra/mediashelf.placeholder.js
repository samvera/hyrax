/**
 * jQuery.placeholder - Placeholder plugin for input fields
 * Written by Blair Mitchelmore (blair DOT mitchelmore AT gmail DOT com)
 *    with bug fixes for MediaShelf by Paul Cantrell
 * Licensed under the WTFPL (http://sam.zoy.org/wtfpl/).
 **/
(function($) {
	$.fn.placeholder = function(settings) {
	    settings = settings || {};
	    var key = settings.dataKey || "placeholderValue";
	    var attr = settings.attr || "placeholder";
	    var className = settings.className || "placeholder";
	    var values = settings.values || [];
	    var block = settings.blockSubmit || false;
	    var blank = settings.blankSubmit || false;
	    var submit = settings.onSubmit || false;
	    var value = settings.value || "";
	    var position = settings.cursor_position || 0;

	    var version = parseFloat($.browser.version)
	    if(($.browser.webkit && version >= 4) || ($.browser.mozilla && version >= 2)) {
	        // placeholder supported natively
	        return false;
	    }
    
	    var updatePlaceholderState = function() {
	        if ($.trim($(this).val()) === "" || $(this).val() == $.data(this, key))
	            $(this).addClass(className).val($.data(this, key));
	        else
	            $(this).removeClass(className);
	    }
    
	    return this.filter(":input").each(function(index) { 
	        $.data(this, key, values[index] || $(this).attr(attr)); 
	    }).each(updatePlaceholderState)
	    .blur(updatePlaceholderState)
	    .change(updatePlaceholderState)
	    .focus(function() {
	        if ($.trim($(this).val()) === $.data(this, key)) 
	            $(this).removeClass(className).val(value)
	            if ($.fn.setCursorPosition) {
	              $(this).setCursorPosition(position);
	            }
	    }).each(function(index, elem) {
	        if (block)
	            new function(e) {
	                $(e.form).submit(function() {
	                    return $.trim($(e).val()) != $.data(e, key)
	                });
	            }(elem);
	        else if (blank)
	            new function(e) {
	                $(e.form).submit(function() {
	                    if ($.trim($(e).val()) == $.data(e, key)) 
	                        $(e).removeClass(className).val("");
	                    return true;
	                });
	            }(elem);
	        else if (submit)
	            new function(e) { $(e.form).submit(submit); }(elem);
	    });
	};

	$(document).ready(function() {
	    $('input').placeholder({ blankSubmit: true });
	});
})(jQuery)
