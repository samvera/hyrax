# frozen_string_literal: true

module Wings
  ##
  # Converts `ValkyrieResource` objects to legacy `ActiveFedora::Base` objects.
  #
  # @example
  #   work     = GenericWork.new(title: ['Comet in Moominland'])
  #   resource = GenericWork.valkyrie_resource
  #
  #   ActiveFedoraConverter.new(resource: resource).convert == work # => true
  #
  # @note the `Valkyrie::Resource` object passed to this class **must** have an
  #   `#internal_resource` mapping it to an `ActiveFedora::Base` class.
  class ActiveFedoraConverter
    ##
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    attr_accessor :resource

    ##
    # @param [Valkyrie::Resource]
    def initialize(resource:)
      @resource = resource
    end

    ##
    # @return [Hash<Symbol, Object>]
    def attributes
      attrs = resource.attributes

      # avoid reflections for now; `*_ids` can't be passed as attributes.
      # handling for reflections needs to happen in future work
      attrs = attrs.reject { |k, _| k.to_s.end_with? '_ids' }

      attrs.delete(:internal_resource)
      attrs.delete(:new_record)
      attrs.delete(:id)
      attrs.delete(:alternate_ids)

      attrs.compact
    end

    ##
    # @return [ActiveFedora::Base]
    def convert
      resource.internal_resource.new(attributes).tap { |obj| obj.id = id unless id.empty? }
    end

    ##
    # @return [String]
    def id
      resource.alternate_ids.first.to_s
    end
  end
end
