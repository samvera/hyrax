// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Sufia = {
    initialize: function () {
        this.autocomplete();
        this.popovers();
        this.permissions();
        this.notifications();
        this.transfers();
        this.editor();
        this.fileManager();
        this.selectWorkType();
        this.datatable();
        this.admin();
    },

    admin: function() {
      var AdminSetControls = require('sufia/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    datatable: function () {
        // This keeps the datatable from being added to a table that already has it.
        // This is a problem when turbolinks is active.
        if ($('.dataTables_wrapper').size() === 0) {
            $('.datatable').DataTable();
        }
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

    editor: function () {
        var element = $("[data-behavior='work-form']")
        if (element.length > 0) {
          var Editor = require('sufia/editor');
          new Editor(element)
        }
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
        // On the edit work page
        new perm.PermissionsControl($("#share"), 'tmpl-work-grant');
        // On the edit fileset page
        new perm.PermissionsControl($("#permission"), 'tmpl-file-set-grant');
        // On the batch edit page
        new perm.PermissionsControl($("#form_permissions"), 'tmpl-work-grant');
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

    selectWorkType: function () {
        var selectWork = require('sufia/select_work_type');
        $("[data-behavior=select-work]").each(function () {
            new selectWork($(this))
        });
    },

    fileManager: function () {
        var fm = require('curation_concerns/file_manager');
        var file_manager = new fm
    },

};
