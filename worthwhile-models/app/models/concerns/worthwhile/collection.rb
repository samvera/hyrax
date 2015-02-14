module Worthwhile
  module Collection
    extend ActiveSupport::Concern

    included do
      include Hydra::Collection
      include ::CurationConcern::CollectionModel
      include Hydra::Collections::Collectible
      include ::CurationConcern::WithGenericFiles

      # override Hydra::Collection to add :solr_page_size
      has_and_belongs_to_many :members, predicate:  ActiveFedora::RDF::Fcrepo::RelsExt.hasCollectionMember, class_name: "ActiveFedora::Base" , after_remove: :update_member,
                              solr_page_size: 70
    end

  end

end
