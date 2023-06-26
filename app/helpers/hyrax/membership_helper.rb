# frozen_string_literal: true

module Hyrax
  module MembershipHelper
    ##
    # @param resource [#member_of_collection_ids, #member_of_collections_json]
    #
    # @return [String] JSON for `data-members`
    #
    # @todo optimize collection name lookup. the legacy `WorkForm`
    #   implementation pulls all the collections already (though maybe with
    #   instance-level caching?), but we should consider doing this more
    #   efficiently.
    #
    # @see app/assets/javascripts/hyrax/relationships.js
    def member_of_collections_json(resource)
      # this is where we return for dassie
      return resource.member_of_collections_json if
        resource.respond_to?(:member_of_collections_json)

      resource = resource.model if resource.respond_to?(:model)

      existing_collections_array = Hyrax.custom_queries.find_collections_for(resource: resource) + add_collection_from_params
      existing_collections_array.map do |collection|
        { id: collection.id.to_s,
          label: collection.title.first,
          path: url_for(collection) }
      end.to_json
    end

    def add_collection_from_params
      # avoid errors when creating Valkyrie resources from Dashboard >> Works
      return [] if controller.params[:add_works_to_collection].blank?

      # new valkyrie works need the collection from params when depositing directly into an existing collection
      return [Hyrax.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(controller.params[:add_works_to_collection]))] if Hyrax.config.use_valkyrie?

      [::Collection.find(@controller.params[:add_works_to_collection])]
    end

    ##
    # @param resource [#work_members_json]
    #
    # @return [String] JSON for `data-members`
    #
    # @see app/assets/javascripts/hyrax/relationships.js
    def work_members_json(resource)
      return resource.work_members_json if
        resource.respond_to?(:work_members_json)

      resource = resource.model if resource.respond_to?(:model)

      Hyrax.custom_queries.find_child_works(resource: resource).map do |member|
        { id: member.id.to_s,
          label: member.title.first,
          path: main_app.url_for([member, { only_path: true }]) }
      end.to_json
    end
  end
end
