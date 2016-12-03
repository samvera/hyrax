(function($){
  Hyrax.Search = function (element) {
    this.$element = $(element);

    this.init = function() {
      this.$label = this.$element.find('[data-search-element="label"]');
      this.$items = this.$element.find('[data-search-option]');
      this.setDefault();
    }

    this.init();
    this.attachEvents();
  }


  Hyrax.Search.prototype = {
    attachEvents: function() {

      _this = this;
      this.$items.on('click', function(event) {
        event.preventDefault();
        _this.clicked($(this))
      });
    },

    clicked: function($anchor) {
      this.setLabel($anchor.data('search-label'));
      this.setFormAction($anchor.data('search-option'));
    },

    setFormAction: function(path) {
      this.$element.attr('action', path);
    },

    getLabelForValue: function(value) {
      selected = this.$element.find('[data-search-option="'+ value +'"]');
      return selected.data('search-label');
    },

    setDefault: function() {
      this.setLabel(this.getLabelForValue(this.$element.attr('action')));
    },

    setLabel: function(label) {
      this.$label.html(label);
    }

  }

  $.fn.search = function(option) {
    return this.each(function() {
      var $this = $(this);
      var data  = $this.data('search');

      if (!data) $this.data('search', (data = new Hyrax.Search(this)));
    })
  }

})(jQuery);


Blacklight.onLoad(function() {
  $('#search-form-header').search();
});

