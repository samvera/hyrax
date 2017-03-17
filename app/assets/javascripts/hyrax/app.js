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
        this.adminStatisticsGraphs();
        this.tinyMCE();
    },

    tinyMCE: function() {
        if (typeof tinyMCE === "undefined")
            return;
        tinyMCE.init({
            selector: 'textarea.tinymce'
        });
    },

    admin: function() {
      var AdminSetControls = require('hyrax/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    adminStatisticsGraphs: function() {
        var AdminGraphs = require('hyrax/admin/graphs');
        new AdminGraphs(Hyrax.statistics);
    },

    datatable: function () {
        // This keeps the datatable from being added to a table that already has it.
        // This is a problem when turbolinks is active.
        if ($('.dataTables_wrapper').length === 0) {
            $('.datatable').DataTable();
        }
    },

    autocomplete: function () {
        var Autocomplete = require('hyrax/autocomplete');
        var autocomplete = new Autocomplete({
	    "autocompleteFields":
	    ["subject","language","creator","based_near","work"]
	});
        $('.multi_value.form-group').manage_fields({
          add: function(e, element) {
              autocomplete.fieldAdded(element);
	      // Don't mark an added element as readonly even if previous element was
	      $(element).attr('readonly',false);
          }
        });
        autocomplete.setup();
    },

    saveWorkControl: function () {
        var SaveWorkControl = require('hyrax/save_work/save_work_control');
        var control = new SaveWorkControl($("#form-progress"));
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
        var PermissionsControl = require('hyrax/permissions/control');
        // On the edit work page
        new PermissionsControl($("#share"), 'tmpl-work-grant');
        // On the edit fileset page
        new PermissionsControl($("#permission"), 'tmpl-file-set-grant');
        // On the batch edit page
        new PermissionsControl($("#form_permissions"), 'tmpl-work-grant');
    },

    notifications: function () {
        var Notifications = require('hyrax/notifications');
        $('[data-update-poll-url]').each(function () {
            var interval = $(this).data('update-poll-interval');
            var url = $(this).data('update-poll-url');
            new Notifications(url, interval);
        });
    },

    transfers: function () {
        $("#proxy_deposit_request_transfer_to").userSearch();
    },

    relationshipsTable: function () {
        var RelationshipsTable = require('hyrax/relationships/table');
        $('table.relationships-ajax-enabled').each(function () {
            new RelationshipsTable($(this));
        });
    },

    selectWorkType: function () {
        var SelectWorkType = require('hyrax/select_work_type');
        $("[data-behavior=select-work]").each(function () {
            new SelectWorkType($(this));
        });
    },

    fileManager: function () {
        var FileManager = require('hyrax/file_manager');
        new FileManager();
    },

    authoritySelect: function(options) {
	var AuthoritySelect = require('hyrax/authority_select');
	var authoritySelect = new AuthoritySelect(options);
	authoritySelect.initialize();
    },

    // Saved so that inline javascript can put data somewhere.
    statistics: {}

};
