// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Sufia = {
  initialize: function() {
    this.save_work_control();
    this.popovers();
    this.permissions();
    this.notifications();
  },

  save_work_control: function() {
    var sw = require('sufia/save_work/save_work_control');
    new sw.SaveWorkControl($("#form-progress")).activate();
  },

  // initialize popover helpers
  popovers: function() {
    $("a[data-toggle=popover]").popover({ html: true })
				 .click(function() { return false; });
  },


  permissions: function() {
    var perm = require('sufia/permissions/control');
    new perm.PermissionsControl($("#share"), 'generic_work', 'tmpl-work-grant');
    new perm.PermissionsControl($("#permission"), 'file_set', 'tmpl-file-set-grant');
  },

  notifications: function() {
    var note = require('sufia/notifications');
    $('[data-update-poll-url]').each(function() {
      var interval = $(this).data('update-poll-interval');
      var url = $(this).data('update-poll-url');
      new note.Notifications(url, interval);
    });
  }
};

Blacklight.onLoad(function() {
  Sufia.initialize();
});
