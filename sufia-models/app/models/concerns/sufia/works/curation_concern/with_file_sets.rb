module Sufia::Works
  module CurationConcern
    module WithFileSets
      extend ActiveSupport::Concern

      included do
        # This used to have a hasFile relation when in hydra-works.  That does not seem to exist so I am using hasPart instead
        has_many :file_sets, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasPart, class_name: "FileSet"

        # has_many :file_sets, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        before_destroy :before_destroy_cleanup_file_sets

        attr_accessor :files
      end

      def before_destroy_cleanup_file_sets
        file_sets.each(&:destroy)
      end

      def copy_visibility_to_files
        file_sets.each do |fs|
          fs.visibility = visibility
          fs.save!
        end
      end
    end
  end
end
