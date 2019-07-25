# frozen_string_literal: true

module Hyrax
  ##
  # ACLs for `Hyrax::Resource` models
  class AccessControlList
    ##
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    # @!attribute [r] persister
    #   @return [#save]
    # @!attribute [r] query_service
    #   @return [#find_inverse_references_by]
    attr_reader :persister, :query_service
    attr_accessor :resource

    ##
    # @param resource [Valkyrie::Resource]
    def initialize(resource:, persister: Hyrax.persister, query_service: Hyrax.query_service)
      self.resource  = resource
      @persister     = persister
      @query_service = query_service
    end

    ##
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def <<(permission)
      permission.access_to = resource.id

      additions << permission

      true
    end
    alias add <<

    ##
    # @param permission [Hyrax::Permission]
    #
    # @return [Boolean]
    def delete(permission)
      additions.delete(permission)
      deletions << permission

      true
    end

    ##
    # @return [Boolean]
    def pending_changes?
      additions.any? || deletions.any?
    end

    ##
    # @return [Enumerable<Hyrax::Permission>]
    def permissions
      Set.new(query_service.find_inverse_references_by(resource: resource, property: :access_to)) -
        deletions |
        additions
    end

    ##
    # Saves the ACL for the resource, by saving each permission policy
    #
    # @return [Boolean]
    def save
      return true unless pending_changes?

      deletions.each { |p| persister.delete(resource: p) }
      deletions.clear

      additions.each { |p| persister.save(resource: p) }
      additions.clear

      true
    end

    private

      def additions
        @additions ||= Set.new
      end

      def deletions
        @deletions ||= Set.new
      end
  end
end
