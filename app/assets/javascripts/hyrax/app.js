// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Hyrax = {
    initialize: function () {
        this.autocomplete();
        this.saveWorkControl();
        this.saveWorkFixed();
        this.popovers();
        this.permissions();
        this.notifications();
        this.transfers();
        this.relationshipsTable();
        this.fileManager();
        this.selectWorkType();
        this.datatable();
        this.admin();
    },

    admin: function() {
      var AdminSetControls = require('hyrax/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    datatable: function () {
        // This keeps the datatable from being added to a table that already has it.
        // This is a problem when turbolinks is active.
        if ($('.dataTables_wrapper').length === 0) {
            $('.datatable').DataTable();
        }
    },

    autocomplete: function () {
        var ac = require('hyrax/autocomplete');
        var autocomplete = new ac.Autocomplete()
        $('.multi_value.form-group').manage_fields({
          add: function(e, element) {
            autocomplete.fieldAdded(element)
          }
        });
        autocomplete.setup();
    },

    saveWorkControl: function () {
        var sw = require('hyrax/save_work/save_work_control');
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
        var perm = require('hyrax/permissions/control');
        // On the edit work page
        new perm.PermissionsControl($("#share"), 'tmpl-work-grant');
        // On the edit fileset page
        new perm.PermissionsControl($("#permission"), 'tmpl-file-set-grant');
        // On the batch edit page
        new perm.PermissionsControl($("#form_permissions"), 'tmpl-work-grant');
    },

    notifications: function () {
        var note = require('hyrax/notifications');
        $('[data-update-poll-url]').each(function () {
            var interval = $(this).data('update-poll-interval');
            var url = $(this).data('update-poll-url');
            new note.Notifications(url, interval);
        });
    },

    transfers: function () {
        $("#proxy_deposit_request_transfer_to").userSearch();
    },

    relationshipsTable: function () {
        var rel = require('hyrax/relationships/table');
        $('table.relationships-ajax-enabled').each(function () {
            new rel.RelationshipsTable($(this));
        });
    },

    selectWorkType: function () {
        var selectWork = require('hyrax/select_work_type');
        $("[data-behavior=select-work]").each(function () {
            new selectWork($(this))
        });
    },

    fileManager: function () {
        var fm = require('hyrax/file_manager');
        var file_manager = new fm
    },

};
