(function( $ ){

  $.fn.multiForm = function( options ) {  

    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    function addField() {
      count = $(this).closest('.form-group').find('input').size();
      var cloneId = this.id.replace("submit", "clone");
      var newId = this.id.replace("submit", "elements");
      var cloneElem = $('#'+cloneId).clone();
      // change the add button to a remove button
      var plusbttn = cloneElem.find('#'+this.id);
      var sr_hidden = '<span aria-hidden="true"><i class="glyphicon glyphicon-remove"></i></span>';
      var sr_only = '<span class="sr-only">remove this ' + this.name.replace("_", " ") + '</span>';
      var remove_button = sr_hidden + sr_only; 
      plusbttn.html(remove_button);
      plusbttn.on('click',removeField);


      // remove the help tag on subsequent added fields
      cloneElem.find('.formHelp').remove();
      cloneElem.find('.modal-div').remove();

      //clear out the value for the element being appended
      //so the new element has a blank value
      // Note: there may be more than one input field. Example:
      //   creator_name
      //   creator_role
      textFields = cloneElem.find('input[type=text]')
      $.each(textFields, function(n, tf) {
        newName = $(tf).attr('name').replace('[0]', '['+count+']');
        $(tf).attr('name', newName).val('').attr("required", false)
      })

      if (settings.afterAdd) {
        settings.afterAdd(this, cloneElem)
      }

      $('#'+newId).append(cloneElem);
      cloneElem.find('input[type=text]').focus();
      return false;
    }

    function removeField () {
      // get parent and remove it
      $(this).parent().remove();
      return false;
    }

    return this.each(function() {        

      // Tooltip plugin code here
      /*
       * adds additional metadata elements
       */
      $('.adder', this).click(addField);

      $('.remover', this).click(removeField);


    });

  };
})( jQuery );  

