module CurationConcerns
  module GenericFile
    module BelongsToUploadSets
      extend ActiveSupport::Concern
      included do
        belongs_to :upload_set, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end

      # Is this file in the middle of being processed by an UploadSet?
      def processing?
        try(:upload_set).try(:status) == ['processing'.freeze]
      end
    end
  end
end
