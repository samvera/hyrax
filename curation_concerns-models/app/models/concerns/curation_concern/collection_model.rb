module CurationConcern
  module CollectionModel
    extend ActiveSupport::Concern

    include Hydra::AccessControls::Permissions
    include Hydra::AccessControls::WithAccessRight
    include Sufia::Noid
    include CurationConcern::HumanReadableType
    include Hydra::Collection
    include Hydra::Collections::Collectible
    include CurationConcern::HasRepresentative

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
        self.save
      end
    end

    def to_s
      self.title.present? ? title : "No Title"
    end

    def to_solr(solr_doc={})
      super(solr_doc).tap do |solr_doc|
        Solrizer.set_field(solr_doc, 'generic_type', human_readable_type, :facetable)
      end
    end

    def can_be_member_of_collection?(collection)
      collection == self ? false : true
    end


    # ------------------------------------------------
    # overriding method from active-fedora:
    # lib/active_fedora/semantic_node.rb
    #
    # The purpose of this override is to ensure that
    # a collection cannot contain itself.
    #
    # TODO:  After active-fedora 7.0 is released, this
    # logic can be moved into a before_add callback.
    # ------------------------------------------------
    def add_relationship(predicate, target, literal=false)
      return if self == target
      super
    end

    private
    def can_add_to_members?(collectible)
      collectible.can_be_member_of_collection?(self)
    rescue NoMethodError
      false
    end

  end
end
