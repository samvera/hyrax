// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Hyrax = {
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
        this.adminStatisticsGraphs();
        this.tinyMCE();
        this.sidebar();
        this.authoritySelect();
    },

    // Add WYSIWYG editor functionality to editable content blocks
    tinyMCE: function() {
        if (typeof tinyMCE === "undefined")
            return;
        tinyMCE.init({
            selector: 'textarea.tinymce'
        });
    },

    // Add search for user/group to the edit an admin set's participants page
    admin: function() {
      var AdminSetControls = require('hyrax/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    // Pretty graphs on the dashboard page
    adminStatisticsGraphs: function() {
        var AdminGraphs = require('hyrax/admin/graphs');
        new AdminGraphs(Hyrax.statistics);
    },

    // Sortable/pageable tables
    datatable: function () {
        // This keeps the datatable from being added to a table that already has it.
        // This is a problem when turbolinks is active.
        if ($('.dataTables_wrapper').length === 0) {
            $('.datatable').DataTable();
        }
    },

    // Autocomplete fields for the work edit form (based_near, subject, language, child works)
    // TODO: this could move to editor()
    autocomplete: function () {
        var Autocomplete = require('hyrax/autocomplete')
        var autocomplete = new Autocomplete()

        $('[data-autocomplete]').each((function() {
          var data = $(this).data()
          autocomplete.setup({'element' : $(this), 'data': data})
        }))

        $('.multi_value.form-group').manage_fields({
          add: function(e, element) {
              autocomplete.setup({'element':$(element), 'data':$(element).data()})
	      // Don't mark an added element as readonly even if previous element was
	      $(element).attr('readonly', false)
          }
        })
    },

    // Functionality for the work edit page
    editor: function () {
        var element = $("[data-behavior='work-form']")
        if (element.length > 0) {
          var Editor = require('hyrax/editor');
          new Editor(element)
        }
    },

    // Popover help modals. Used on the user profile page.
    popovers: function () {
        $("a[data-toggle=popover]").popover({html: true})
            .click(function () {
                return false;
            });
    },

    // Add access grants for a user/group to a work/fileset/collection
    // TODO: This could get moved to editor() or similar
    permissions: function () {
        var PermissionsControl = require('hyrax/permissions/control');
        // On the edit work page
        new PermissionsControl($("#share"), 'tmpl-work-grant');
        // On the edit fileset page
        new PermissionsControl($("#permission"), 'tmpl-file-set-grant');
        // On the batch edit page
        new PermissionsControl($("#form_permissions"), 'tmpl-work-grant');
        // On the edit collection page
        new PermissionsControl($("#collection_permissions"), 'tmpl-collection-grant');
    },

    // Polling for user notifications. This is displayed in the navbar.
    notifications: function () {
        var Notifications = require('hyrax/notifications');
        $('[data-update-poll-url]').each(function () {
            var interval = $(this).data('update-poll-interval');
            var url = $(this).data('update-poll-url');
            new Notifications(url, interval);
        });
    },

    // Search for a user to transfer a work to
    transfers: function () {
        $("#proxy_deposit_request_transfer_to").userSearch();
    },

    // Popover menu to select the type of work when starting a deposit
    selectWorkType: function () {
        var SelectWorkType = require('hyrax/select_work_type');
        $("[data-behavior=select-work]").each(function () {
            new SelectWorkType($(this));
        });
    },

    // Minimize/maximize the dashboard sidebar
    sidebar: function () {
        $('.sidebar-toggle').on('click', function() {
            $('.sidebar, .main-content').toggleClass('maximized')
        })
    },

    // Add and reorder files attached to works
    fileManager: function () {
        var FileManager = require('hyrax/file_manager');
        new FileManager();
    },
    // Used when you have a linked data field that can have terms from multiple
    // authorities.
    // TODO: should be moved to the editor()
    
    authoritySelect: function() {
	var AuthoritySelect = require('hyrax/authority_select');
        $("[data-authority-select]").each(function() {
            var authoritySelect = $(this).data().authoritySelect
            new AuthoritySelect({selectBox: 'select.' + authoritySelect, inputField: 'input.' + authoritySelect});
        })
    },

    // Saved so that inline javascript can put data somewhere.
    statistics: {}

};
