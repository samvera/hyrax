// This widget manages the adding and removing of repeating fields.
// There are a lot of assumptions about the structure of the classes and elements.
// These assumptions are reflected in the MultiValueInput class.

(function($){
  $.widget( "curate.manage_fields", {
    options: {
      change: null,
      add: null,
      remove: null
    },

    _create: function() {
      this.element.addClass("managed");
      $('.field-wrapper', this.element).addClass("input-append");

      this.controls = $("<span class=\"field-controls\">");
      this.remover  = $("<button class=\"btn btn-danger remove\"><i class=\"icon-white icon-minus\"></i><span>Remove</span></button>");
      this.adder    = $("<button class=\"btn btn-success add\"><i class=\"icon-white icon-plus\"></i><span>Add</span></button>");

      $('.field-wrapper', this.element).append(this.controls);
      $('.field-wrapper:not(:last-child) .field-controls', this.element).append(this.remover);
      $('.field-controls:last', this.element).append(this.adder);

      this._on( this.element, {
        "click .remove": "remove_from_list",
        "click .add": "add_to_list"
      });
    },

    add_to_list: function( event ) {
      event.preventDefault();

      var $activeField = $(event.target).parents('.field-wrapper'),
          $activeFieldControls = $activeField.children('.field-controls'),
          $removeControl = this.remover.clone(),
          $newField = $activeField.clone(),
          $listing = $('.listing', this.element),
          $warningSpan  = $("<span class=\'message warning\'>cannot add new empty field</span>");
      if ($activeField.children('input').val() === '') {
          $listing.children('.warning').remove();
          $listing.append($warningSpan);
      }
      else{
        $listing.children('.warning').remove();
        $('.add', $activeFieldControls).remove();
        $activeFieldControls.prepend($removeControl);
        $newChildren = $newField.children('input');
        $newChildren.
          val('').
          removeProp('required');
        $listing.append($newField);
        $newChildren.first().focus();
        this._trigger("add");
      }
    },

    remove_from_list: function( event ) {
      event.preventDefault();

      $(event.target)
        .parents('.field-wrapper')
        .remove();

      this._trigger("remove");
    },

    _destroy: function() {
      this.actions.remove();
      $('.field-wrapper', this.element).removeClass("input-append");
      this.element.removeClass( "managed" );
    }
  });
})(jQuery);
