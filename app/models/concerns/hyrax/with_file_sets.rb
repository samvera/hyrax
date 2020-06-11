# frozen_string_literal: true
module Hyrax
  module WithFileSets
    extend ActiveSupport::Concern

    ##
    # @deprecated Use 'Hyrax::VisibilityPropagator' instead.
    def copy_visibility_to_files
      Deprecation.warn "Use 'Hyrax::VisibilityPropagator' instead."

      file_sets.each do |fs|
        fs.visibility = visibility
        fs.save!
      end
    end
  end
end
