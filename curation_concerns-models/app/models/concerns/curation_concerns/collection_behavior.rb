module CurationConcerns
   module CollectionBehavior
    extend ActiveSupport::Concern

    include Hydra::AccessControls::Permissions
    include Hydra::AccessControls::WithAccessRight
    include CurationConcerns::Noid
    include CurationConcerns::HumanReadableType
    include Hydra::Collection
    include Hydra::Collections::Collectible
    include CurationConcerns::HasRepresentative

    included do
      before_save :remove_self_from_members
    end

    # Ensures that a collection never contains itself
    def remove_self_from_members
      if member_ids.include?(id)
        members.delete(self)
      end
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
