# frozen_string_literal: true
module Hyrax
  module WorkFormHelper
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
    # @param form [Hyrax::Forms::WorkForm]
    # @return [Array<String>] the list of names of tabs to be rendered in the form
    def form_tabs_for(form:)
      if form.instance_of? Hyrax::Forms::BatchUploadForm
        %w[files metadata relationships]
      else
        %w[metadata files relationships]
      end
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
    # @param form [Hyrax::Forms::WorkForm]
    # @return [Array<String>] the list of names of sections to be rendered in the form_progress panel
    def form_progress_sections_for(*)
      []
    end
  end
end
