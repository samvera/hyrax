module Hydra::AccessControls
  class EmbargoIndexer
    def initialize(object)
      @object = object
    end

    def generate_solr_document
      @object.to_hash
    end
  end
end
