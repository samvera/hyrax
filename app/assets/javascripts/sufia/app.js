// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Sufia = {
  initialize: function() {
    this.save_work_control();
    this.popovers();
  },

  save_work_control: function() {
    var sw = require('sufia/save_work/save_work_control');
    new sw.SaveWorkControl($("#form-progress")).activate();
  },

  // initialize popover helpers
  popovers: function() {
    $("a[data-toggle=popover]").popover({ html: true })
				 .click(function() { return false; });
  }
};

Blacklight.onLoad(function() {
  Sufia.initialize();
});
