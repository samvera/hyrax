module Sufia::Works
  module CurationConcern
    module WithGenericFiles
      extend ActiveSupport::Concern

      included do
        # This used to have a hasFile relation when in hydra-works.  That does not seem to exist so I am using hasPart instead
        has_many :files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: "GenericFile"
        #has_many :generic_files, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
        before_destroy :before_destroy_cleanup_generic_files
      end

      def before_destroy_cleanup_generic_files
        files.each(&:destroy)
      end
    end
  end
end
