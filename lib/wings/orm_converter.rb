# frozen_string_literal: true

require 'wings/transformer_value_mapper'
require 'wings/models/concerns/collection_behavior'
require 'wings/hydra/works/models/concerns/work_valkyrie_behavior'
require 'wings/hydra/works/models/concerns/file_set_valkyrie_behavior'

module Wings
  ##
  # Transform AF object class to Valkyrie::Resource class representation.
  #
  class OrmConverter
    ##
    # @param reflections [Hash<Symbol, Object>]
    #
    # @return [Array<Symbol>]
    def self.relationship_keys_for(reflections:)
      relationships = reflections
                      .keys
                      .reject { |k| k.to_s.include?('id') }
                      .map { |k| k.to_s.singularize + '_ids' }
      relationships.delete('member_ids') # Remove here.  Members will be extracted as ordered_members in attributes method.
      relationships.delete('ordered_member_proxy_ids') # This does not have a Valkyrie equivalent.
      relationships
    end

    ##
    # Selects an existing base class for the generated valkyrie class
    #
    # @return [Class]
    def self.base_for(klass:)
      klass.try(:valkyrie_class) ||
        ModelRegistry.reverse_lookup(klass) ||
        Hyrax::Resource
    end

    ##
    # @param klass [Class] an `ActiveFedora` model class
    #
    # @return [Class] a dyamically generated `Valkyrie::Resource` subclass
    #   mirroring the provided `ActiveFedora` model
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength because metaprogramming a class
    #   results in long methods
    def self.to_valkyrie_resource_class(klass:)
      relationship_keys = klass.respond_to?(:reflections) ? relationship_keys_for(reflections: klass.reflections) : []
      relationship_keys.delete('member_ids')
      relationship_keys.delete('member_of_collection_ids')
      reflection_id_keys = klass.respond_to?(:reflections) ? klass.reflections.keys.select { |k| k.to_s.end_with? '_id' } : []

      Class.new(base_for(klass: klass)) do
        include Wings::CollectionBehavior if klass.included_modules.include?(Hyrax::CollectionBehavior)
        include Wings::Works::WorkValkyrieBehavior if klass.included_modules.include?(Hyrax::WorkBehavior)
        include Wings::Works::FileSetValkyrieBehavior if klass.included_modules.include?(Hyrax::FileSetBehavior)

        # store a string we can resolve to the internal resource
        @internal_resource = klass.try(:to_rdf_representation) || klass.name

        class << self
          attr_reader :internal_resource

          def name
            ancestors[1..-1].find { |parent| parent < ::Valkyrie::Resource }&.name
          end
        end

        def self.to_s
          internal_resource
        end

        klass.properties.each_key do |property_name|
          attribute property_name.to_sym, ::Valkyrie::Types::String
        end

        relationship_keys.each do |linked_property_name|
          attribute linked_property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        end

        reflection_id_keys.each do |property_name|
          attribute property_name, ::Valkyrie::Types::ID
        end

        def internal_resource
          self.class.internal_resource
        end
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
