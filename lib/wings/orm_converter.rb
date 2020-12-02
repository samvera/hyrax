# frozen_string_literal: true

module Wings
  ##
  # Transform AF object class to Valkyrie::Resource class representation.
  class OrmConverter
    ##
    # @param reflections [Hash<Symbol, Object>]
    #
    # @return [Array<Symbol>]
    def self.relationship_keys_for(reflections:)
      Hash(reflections).keys.map do |k|
        key_string = k.to_s
        next if key_string.include?('id') || key_string.include?('proxies')
        key_string.singularize + '_ids'
      end.compact
    end

    ##
    # Selects an existing base class for the generated valkyrie class
    #
    # @return [Class]
    def self.base_for(klass:)
      mapped_class = klass.try(:valkyrie_class) || ModelRegistry.reverse_lookup(klass)
      return mapped_class if mapped_class
      klass < Hydra::Works::WorkBehavior ? Hyrax::Work : Hyrax::Resource
    end

    ##
    # @param klass [Class] an `ActiveFedora` model class
    #
    # @return [Class] a dyamically generated `Valkyrie::Resource` subclass
    #   mirroring the provided `ActiveFedora` model
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/BlockLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength because metaprogramming a class
    #   results in long methods
    def self.to_valkyrie_resource_class(klass:)
      relationship_keys = klass.respond_to?(:reflections) ? relationship_keys_for(reflections: klass.reflections) : []
      reflection_id_keys = klass.respond_to?(:reflections) ? klass.reflections.keys.select { |k| k.to_s.end_with? '_id' } : []

      Class.new(base_for(klass: klass)) do
        # store a string we can resolve to the internal resource
        @internal_resource = klass.try(:to_rdf_representation) || klass.name

        class << self
          attr_reader :internal_resource

          def name
            _canonical_valkyrie_model&.name
          end

          ##
          # @api private
          def _canonical_valkyrie_model
            ancestors[1..-1].find { |parent| parent < ::Valkyrie::Resource }
          end
        end

        def self.to_s
          internal_resource
        end

        klass.properties.each_key do |property_name|
          next if fields.include?(property_name.to_sym)

          if klass.properties[property_name].multiple?
            attribute property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::Anything).optional
          else
            attribute property_name.to_sym, ::Valkyrie::Types::Anything.optional
          end
        end

        relationship_keys.each do |linked_property_name|
          next if fields.include?(linked_property_name.to_sym)
          attribute linked_property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        end

        reflection_id_keys.each do |property_name|
          next if fields.include?(property_name.to_sym)
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
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
