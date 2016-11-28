module Sufia
  module AdminSetBehavior
    extend ActiveSupport::Concern

    include Hydra::AccessControls::WithAccessRight
    include Sufia::Noid
    include Sufia::HumanReadableType
    include Sufia::HasRepresentative

    included do
      validates_with HasOneTitleValidator
      class_attribute :human_readable_short_description, :indexer
      self.indexer = Sufia::AdminSetIndexer
      property :title, predicate: ::RDF::Vocab::DC.title do |index|
        index.as :stored_searchable, :facetable
      end
      property :description, predicate: ::RDF::Vocab::DC.description do |index|
        index.as :stored_searchable
      end

      property :creator, predicate: ::RDF::Vocab::DC11.creator do |index|
        index.as :symbol
      end

      has_many :members,
               predicate: ::RDF::Vocab::DC.isPartOf,
               class_name: 'ActiveFedora::Base'
    end

    def to_s
      title.present? ? title : 'No Title'
    end
  end
end
