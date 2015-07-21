module CurationConcerns
  module CollectionBehavior
    extend ActiveSupport::Concern

    include Hydra::Works::CollectionBehavior

    include Hydra::AccessControls::Permissions
    include Hydra::AccessControls::WithAccessRight
    include CurationConcerns::Noid
    include CurationConcerns::HumanReadableType
    include Hydra::Collection
    include Hydra::Collections::Collectible
    include CurationConcerns::HasRepresentative
    include CurationConcerns::Permissions

    included do
      validates :title, presence: true
    end

    def add_member(collectible)
      if can_add_to_members?(collectible)
        self.members << collectible
        save
      end
    end

    def to_s
      title.present? ? title : "No Title"
    end

    def bytes
      members.reduce(0) { |sum, gf| sum + gf.content.size.to_i }
    end

    def to_solr(solr_doc={})
      super(solr_doc).tap do |solr_doc|
        Solrizer.set_field(solr_doc, 'generic_type', human_readable_type, :facetable)
      end
    end

    def can_be_member_of_collection?(collection)
      collection == self ? false : true
    end

    private

    def can_add_to_members?(collectible)
      collectible.try(:can_be_member_of_collection?, self)
    end
  end
end
