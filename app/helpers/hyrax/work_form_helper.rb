# frozen_string_literal: true
module Hyrax
  module WorkFormHelper
    ##
    # @todo this implementation hits database backends (solr) and is invoked
    #   from views. refactor to avoid
    # @return  [Array<Array<String, String, Hash>] options for the admin set drop down.
    def admin_set_options
      return @admin_set_options.select_options if @admin_set_options

      service = Hyrax::AdminSetService.new(controller)
      Hyrax::AdminSetOptionsPresenter.new(service).select_options
    end

    ##
    # This helper allows downstream applications and engines to add/remove/reorder the tabs to be
    # rendered on the work form.
    #
    # @example with additional tabs
    #  Override this helper and ensure that it loads after Hyrax's helpers.
    #  module WorksHelper
    #    def form_tabs_for(form:)
    #      super + ["my_new_tab"]
    #    end
    #  end
    #  Add the new section partial at app/views/hyrax/base/_form_my_new_tab.html.erb
    #
    # @todo The share tab isn't included because it wasn't in guts4form.  guts4form should be
    #   cleaned up so share is treated the same as other tabs and can be included below.
    # @param form [Hyrax::Forms::WorkForm, Hyrax::Forms::ResourceForm]
    # @return [Array<String>] the list of names of tabs to be rendered in the form
    def form_tabs_for(form:)
      if form.instance_of? Hyrax::Forms::BatchUploadForm
        %w[files metadata relationships]
      else
        %w[metadata files relationships]
      end
    end

    ##
    # This helper allows downstream applications and engines to change the label of tabs to be
    # rendered on the work form.
    #
    # @example passing information from the form into the translations
    #  Override this helper and ensure that it loads after Hyrax's helpers.
    #  module WorksHelper
    #    def form_tab_label_for(form:, tab:)
    #      if tab == 'metadata'
    #        t("hyrax.works.form.tab.#{tab}", title: form.model.title.first)
    #      else
    #        super
    #      end
    #    end
    #  end
    #
    # @param form [Hyrax::Forms::WorkForm]
    # @param tab [String]
    # @return [String] the label of the tab to be rendered in the form
    def form_tab_label_for(form:, tab:) # rubocop:disable Lint/UnusedMethodArgument
      t("hyrax.works.form.tab.#{tab}")
    end

    ##
    # This helper allows downstream applications and engines to add additional sections to be
    # rendered after the visibility section in the Save Work panel on the work form.
    #
    # @example with additional sections
    #  Override this helper and ensure that it loads after Hyrax's helpers.
    #  module WorksHelper
    #    def form_progress_sections_for(*)
    #      super + ["my_new_section"]
    #    end
    #  end
    #  Add the new section partial at app/views/hyrax/base/_form_progress_my_new_section.html.erb
    #
    # @param form [Hyrax::Forms::WorkForm, Hyrax::Forms::ResourceForm]
    # @return [Array<String>] the list of names of sections to be rendered in the form_progress panel
    def form_progress_sections_for(*)
      []
    end

    ##
    # Constructs a hash for a form `select`.
    #
    # @param form [Object]
    #
    # @return [Array<Hash{String => String}>] a map from file set labels to ids for
    #   the parent object
    def form_file_set_select_for(parent:)
      return parent.select_files if parent.respond_to?(:select_files)
      return {} unless parent.respond_to?(:member_ids)

      file_sets =
        Hyrax::PcdmMemberPresenterFactory.new(parent, nil).file_set_presenters

      file_sets.each_with_object({}) do |presenter, hash|
        hash[presenter.title_or_label] = presenter.id
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def in_works_ids_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:in_works_ids]
      else
        form.model.errors[:in_works_ids]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def ordered_member_ids_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:ordered_member_ids]
      else
        form.model.errors[:ordered_member_ids]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def visibility_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:visibility]
      else
        form.model.errors[:visibility]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def embargo_release_date_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:embargo_release_date]
      else
        form.model.errors[:embargo_release_date]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def visibility_after_embargo_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:visibility_after_embargo]
      else
        form.model.errors[:visibility_after_embargo]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def lease_expiration_date_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:lease_expiration_date_errors]
      else
        form.model.errors[:lease_expiration_date_errors]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message
    def visibility_after_lease_errors_for(form:)
      case form
      when Hyrax::ChangeSet
        form.errors[:visibility_after_lease]
      else
        form.model.errors[:visibility_after_lease]
      end
    end

    ##
    # This helper retrieves errors based on form type.
    #
    # @param form [Hyrax::Forms::WorkForm] or Hyrax::ChangeSet
    # @return [String] specific error message(s)
    def full_collections_errors(form:)
      error_messages = []
      form.errors.messages.each_value { |v| error_messages << v.first }
      error_messages.join('; ')
    end

    def flash_message_types(model = nil)
      if model&.errors&.any?
        { notice: 'alert-success', alert: 'alert-warning' }
      else
        { notice: 'alert-success', error: 'alert-danger', alert: 'alert-warning' }
      end
    end
  end
end
