# frozen_string_literal: true
module Hyrax
  module WorkFormHelper
    include Hyrax::RedirectsTabHelper

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
      tabs = if form.instance_of? Hyrax::Forms::BatchUploadForm
               %w[files metadata relationships]
             else
               %w[metadata files relationships]
             end
      tabs << 'redirects' if redirects_tab?(form)
      tabs
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
    # Constructs options for a form `select`.
    #
    # @param form [Object]
    #
    # @return [Array<Array(String, String)>] label/id pairs for the work's own
    #   file sets and all descendant works' file sets (legacy forms return their
    #   own label => id Hash via #select_files)
    def form_file_set_select_for(parent:)
      return parent.select_files if parent.respond_to?(:select_files)
      return {} unless parent.respond_to?(:member_ids)

      @form_file_set_select_for ||= begin
        factory = Hyrax::PcdmMemberPresenterFactory.new(parent, nil)

        factory.file_set_presenters.map { |fsp| [fsp.title_or_label, fsp.id] } +
          descendant_file_set_options(factory.work_presenters)
      end
    end

    def descendant_file_set_options(work_presenters, seen: Set.new)
      work_presenters.flat_map do |presenter|
        next [] unless seen.add?(presenter.id.to_s)

        presenter.file_set_presenters.map { |fsp| ["#{fsp.title_or_label} (#{presenter})", fsp.id] } +
          descendant_file_set_options(presenter.work_presenters, seen: seen)
      end
    end
  end
end
