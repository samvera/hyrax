module Hydra
  module Solr
    module Document
      def to_model
        ActiveFedora::Base.load_instance_from_solr(id, self)
      end
    end
  end
end
