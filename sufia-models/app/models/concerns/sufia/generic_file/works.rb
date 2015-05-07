module Sufia
  module GenericFile
    module Works
      extend ActiveSupport::Concern
      included do
        # TODO this could actually be "has_one", but that's not implemented
        belongs_to :generic_work, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasPart
      end

    end
  end
end

