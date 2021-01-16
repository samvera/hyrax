# frozen_string_literal: true
module Hyrax
  ##
  # Responsible for retrieving admin set's members
  class AdminSetMemberService
    ##
    # @!attribute [r] collection
    #   @return [::Collection]
    # @!attribute [r] params
    #   @return [ActionController::Parameters]
    # @!attribute [r] scope
    #   @return [#repository]
    attr_reader :scope, :params, :collection

    ##
    # @!method repository
    #   @note delegated to +:scope+
    delegate :repository, to: :scope

    ##
    # @param [#repository] scope Typically a controller object which responds to +#repository+
    # @param [::Collection] collection an collection of type admin set
    # @param [ActionController::Parameters] params query params
    def initialize(scope:, collection:, params:)
      @scope = scope
      @collection = collection
      @params = params
    end

    ##
    # @api public
    #
    # All members of the given admin_set
    # @return [Blacklight::Solr::Response]
    def available_member_works
      query_solr(query_builder: members_search_builder, query_params: params)
    end

    private

    # @api public
    #
    # set up a member search builder admin set members
    # @return [AdminAdminSetMemberSearchBuilder] new or existing
    def members_search_builder
      @members_search_builder ||= Hyrax::AdminAdminSetMemberSearchBuilder.new(scope: scope, collection: collection)
    end

    ##
    # @api private
    def query_solr(query_builder:, query_params:)
      repository.search(query_builder.with(query_params).query)
    end
  end
end
