// Once, javascript is written in a modular format, all initialization
// code should be called from here.
Hyrax = {
    initialize: function () {
        this.popovers();
        this.permissions();
        this.notifications();
        this.transfers();
        this.workEditor();
        this.fileManager();
        this.selectWorkType();
        this.datatable();
        this.adminSetEditor();
        this.collectionEditor();
        this.collectionTypes();
        this.collectionTypeEditor();
        this.adminStatisticsGraphs();
        this.tinyMCE();
        this.perPage();
        this.sidebar();
        this.batchSelect();
    },

    // Add WYSIWYG editor functionality to editable content blocks
    tinyMCE: function() {
        if (typeof tinyMCE === "undefined")
            return;
        tinyMCE.init({
            selector: 'textarea.tinymce'
        });
    },

    // The AdminSet edit page
    adminSetEditor: function() {
      var AdminSetControls = require('hyrax/admin/admin_set_controls');
      var controls = new AdminSetControls($('#admin-set-controls'));
    },

    // The collectionType edit page
    collectionTypeEditor: function() {
      var CollectionTypeControls = require('hyrax/admin/collection_type_controls');
      var controls = new CollectionTypeControls($('#collection-types-controls'));
    },

    // The Collection edit page
    collectionEditor: function() {
      var CollectionControls = require('hyrax/collections/editor');
      var controls = new CollectionControls($('#collection-controls'));
    },

    // Collection types
    collectionTypes: function() {
      var CollectionTypes = require('hyrax/collection_types');
      var collection_types = new CollectionTypes($('.collection-types-wrapper'))
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

    // The work edit page
    workEditor: function () {
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
    // TODO: This could get moved to workEditor() or similar
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

    // Per Page select will submit its form to change records shown
    perPage: function () {
        var PerPage = require('hyrax/per_page');
        $('#per_page').each(function () {
            new PerPage($(this));
        });
    },

    // Saved so that inline javascript can put data somewhere.
    statistics: {},

    // initialized in hyrax/config.js
    config: {},

    // Adds selected items to the batch before any batch operation is performed
    batchSelect: function () {
        var BatchSelect = require('hyrax/batch_select');
        BatchSelect.initialize_batch_selected();
    }

};
