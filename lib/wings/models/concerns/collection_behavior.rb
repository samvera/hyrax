# frozen_string_literal: true
require 'wings/services/id_converter_service'
require 'wings/hydra/works/models/concerns/collection_valkyrie_behavior'

module Wings
  module CollectionBehavior
    extend ActiveSupport::Concern

    included do
      include Wings::Works::CollectionValkyrieBehavior
    end

    # Add member objects by adding this collection to the objects' member_of_collection association.
    # @param [Enumerable<String> | Enumerable<Valkyrie::ID] the ids of the new child collections and works collection ids
    def add_collections_and_works(new_member_ids, valkyrie: false)
      ### TODO: Change to do this through Valkyrie.  Right now using existing AF method to get multi-membership check.
      af_self = Wings::ActiveFedoraConverter.new(resource: self).convert
      af_ids = valkyrie ? Wings::IdConverterService.convert_to_active_fedora_ids(new_member_ids) : new_member_ids
      af_self.add_member_objects(af_ids)
    end
    alias add_member_objects add_collections_and_works

    ##
    # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the children of this collection
    def child_collections_and_works(valkyrie: false)
      af_collections_and_works = ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id.id}")
      return af_collections_and_works unless valkyrie
      af_collections_and_works.map(&:valkyrie_resource)
    end
    alias member_objects child_collections_and_works

    ##
    # @return [Enumerable<ActiveFedora::Base> | Enumerable<Valkyrie::Resource>] an enumerable over the children of this collection
    def child_collections_and_works_ids(valkyrie: false)
      child_collections_and_works(valkyrie: valkyrie).map(&:id)
    end
    alias member_object_ids child_collections_and_works_ids
  end
end
