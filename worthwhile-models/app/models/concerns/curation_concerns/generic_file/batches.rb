module CurationConcerns
  module GenericFile
    module Batches
      extend ActiveSupport::Concern
      included do
        belongs_to :batch, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end

      # Get the files with a sibling relationship (belongs_to :batch)
      # The batch id is minted when visiting the upload screen and attached
      # to each file when it is done uploading.  The Batch object is not created
      # until all objects are done uploading and the user is redirected to
      # BatchController#edit.  Therefore, we must handle the case where
      # batch_id is set but batch returns nil.
      def related_files
        return [] unless batch
        batch.generic_files.reject { |sibling| sibling.id == id }
      end

      # Is this file in the middle of being processed by a batch?
      def processing?
         try(:batch).try(:status) == ['processing'.freeze]
      end

    end
  end
end

