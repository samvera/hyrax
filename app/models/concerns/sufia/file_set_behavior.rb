module Sufia
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Sufia::WithEvents

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      CatalogController.new.fetch(id).last
    end
  end
end
