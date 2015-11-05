module Sufia
  module FileSet
    module UploadSets
      extend ActiveSupport::Concern
      included do
        belongs_to :batch, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end

      # Is this file in the middle of being processed by a batch?
      def processing?
        try(:batch).try(:status) == ['processing'.freeze]
      end
    end
  end
end
