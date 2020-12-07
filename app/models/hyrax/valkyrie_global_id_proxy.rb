# frozen_string_literal: true

module Hyrax
  ##
  # Support GlobalID and ActiveJob Serialization/Deserialization for
  # `Valkyrie::Resource` models.
  #
  #
  # @example Serializing a Valkyrie::Resource for ActiveJob
  #   resource = Hyrax.query_service.find_by(id: Valkyrie::ID.new('an_id'))
  #
  #   MyJob.perform_later(resource) # #<ActiveJob::SerializationError: Unsupported argument type: >
  #
  #   proxy = Hyrax::ValkyrieGlobalIdProxy.new(resource: resource)
  #   MyJob.perform_later(proxy) # deserializes for `MyJob#perform` as `resource`
  #
  # @see https://github.com/rails/globalid
  class ValkyrieGlobalIdProxy
    include GlobalID::Identification

    ##
    # @!attribute [rw] resource
    #   @return [Hyrax::Resource]
    attr_accessor :resource

    ##
    # @param resource [Hyrax::Resource]
    def initialize(resource:)
      self.resource = resource
    end

    ##
    # @return [Valkyrie::Resource]
    def self.find(id)
      Hyrax.query_service.find_by(id: id)
    end

    ##
    # @return [String]
    def id
      resource.id.to_s
    end
  end
end
