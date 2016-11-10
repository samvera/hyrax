// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Sufia = {
    initialize: function () {
        this.autocomplete();
        this.saveWorkControl();
        this.saveWorkFixed();
        this.popovers();
        this.permissions();
        this.notifications();
        this.transfers();
        this.relationships_table();
        this.file_manager_init();
        this.datatable();
        this.admin();
    },

    admin: function() {
      var AdminSetControls = require('sufia/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    datatable: function () {
        $('.datatable').DataTable();
    },

    autocomplete: function () {
        var ac = require('sufia/autocomplete');
        var autocomplete = new ac.Autocomplete()
        $('.multi_value.form-group').manage_fields({
          add: function(e, element) {
            autocomplete.fieldAdded(element)
          }
        });
        autocomplete.setup();
    },

    saveWorkControl: function () {
        var sw = require('sufia/save_work/save_work_control');
        var control = new sw.SaveWorkControl($("#form-progress"))
    },

    saveWorkFixed: function () {
        // Setting test to false to skip native and go right to polyfill
        FixedSticky.tests.sticky = false;
        $('#savewidget').fixedsticky();
    },

    // initialize popover helpers
    popovers: function () {
        $("a[data-toggle=popover]").popover({html: true})
            .click(function () {
                return false;
            });
    },

    permissions: function () {
        var perm = require('sufia/permissions/control');
        new perm.PermissionsControl($("#share"), 'tmpl-work-grant');
        new perm.PermissionsControl($("#permission"), 'tmpl-file-set-grant');
    },

    notifications: function () {
        var note = require('sufia/notifications');
        $('[data-update-poll-url]').each(function () {
            var interval = $(this).data('update-poll-interval');
            var url = $(this).data('update-poll-url');
            new note.Notifications(url, interval);
        });
    },

    transfers: function () {
        $("#proxy_deposit_request_transfer_to").userSearch();
    },

    relationships_table: function () {
        var rel = require('sufia/relationships/table');
        $('table.relationships-ajax-enabled').each(function () {
            new rel.RelationshipsTable($(this));
        });
    },

    file_manager_init: function () {
        var fm = require('curation_concerns/file_manager');
        var file_manager = new fm
    },

};
