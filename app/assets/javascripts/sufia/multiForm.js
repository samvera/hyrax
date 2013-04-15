(function( $ ){

  $.fn.multiForm = function( options ) {  

    // Create some defaults, extending them with any options that were provided
    var settings = $.extend( { }, options);

    function addField() {
      var cloneId = this.id.replace("submit", "clone");
      var newId = this.id.replace("submit", "elements");
      var cloneElem = $('#'+cloneId).clone();
      // change the add button to a remove button
      var plusbttn = cloneElem.find('#'+this.id);
      plusbttn.html('-<span class="accessible-hidden">remove this '+ this.name.replace("_", " ") +'</span>');
      plusbttn.on('click',removeField);

      // remove the help tag on subsequent added fields
      cloneElem.find('.formHelp').remove();
      cloneElem.find('i').remove();
      cloneElem.find('.modal-div').remove();

      //clear out the value for the element being appended
      //so the new element has a blank value
      cloneElem.find('input[type=text]').attr("value", "");
      cloneElem.find('input[type=text]').attr("required", false);

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

