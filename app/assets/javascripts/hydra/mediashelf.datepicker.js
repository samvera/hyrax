(function($) {
  
  datePickerOpts = {
    dateFormat: 'yy-mm-dd',
    partialDateFormats: ['yy-mm', 'yy'],
    allowShortYear: false,
    ignoreTrailingCharacters: false
  }
  
  validateDate = function(event) {
    try {
        $.datepicker.parseDate(
          $.data(event.target, 'datepicker'),
          event.target.value)
        $(event.target).removeClass('error')
      } catch(err) {
        // Wait to highlight error until user is done typing
        if(event.type != 'keyup')
          $(event.target).addClass('error')
    }
  }
  
  $(document).ready(function() {
    $('.datepicker').datepicker(datePickerOpts).change(validateDate).keyup(validateDate)
  })


	// Monkey patch for fluidinfusion: There is a conflict between fluid.setCaretToEnd's attempt to move cursor
	// into view in Firefox by generating junk keystrokes, and datepicker's filtering of keystrokes. This fixes it
	// by disabling that behavior when a text field has a datepicker.
	var setCaretToEnd_unpatched = fluid.setCaretToEnd;
  fluid.setCaretToEnd = function (control, value) {
		if(!$.data(control, 'datepicker'))
			setCaretToEnd_unpatched(control, value)
		else
    	control.focus()
  }
  
})(jQuery)
