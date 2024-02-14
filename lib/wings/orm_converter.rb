# frozen_string_literal: true

module Wings
  ##
  # @api private
  #
  # Transform AF object class to Valkyrie::Resource class representation.
  class OrmConverter
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
      Class.new(base_for(klass: klass)) do
        # store a string we can resolve to the internal resource
        @internal_resource = klass.try(:to_rdf_representation) || klass.name

        class << self
          attr_reader :internal_resource

          def name
            _canonical_valkyrie_model&.name
          end

          def to_rdf_representation
            name
          end

          ##
          # @return [String]
          def to_s
            internal_resource
          end

          ##
          # @api private
          def _canonical_valkyrie_model
            ancestors[1..-1].find { |parent| parent < ::Valkyrie::Resource }
          end
        end

        ##
        # @return [URI::GID]
        def to_global_id
          URI::GID.build([GlobalID.app, internal_resource, id, {}])
        end

        ##
        # @return [ActiveModel::Base]
        def to_model
          model_class = internal_resource.safe_constantize || self

          Hyrax::ActiveFedoraDummyModel.new(model_class, id)
        end

        klass.properties.each_key do |property_name|
          next if fields.include?(property_name.to_sym)

          if klass.properties[property_name].multiple?
            attribute property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::Anything).optional
          else
            attribute property_name.to_sym, ::Valkyrie::Types::Anything.optional
          end
        end

        # add reflection associations
        (klass.try(:reflections) || []).each do |reflection_key, reflection|
          case reflection
          when ActiveFedora::Reflection::BelongsToReflection, # uses foreign_key SingularRDFPropertyReflection
               ActiveFedora::Reflection::BasicContainsReflection, # ???
               ActiveFedora::Reflection::FilterReflection, # rely on :extending_from
               ActiveFedora::Reflection::HasAndBelongsToManyReflection, # uses foreign_key RDFPropertyReflection
               ActiveFedora::Reflection::HasManyReflection, # captured by inverse relation
               ActiveFedora::Reflection::HasSubresourceReflection, # ???
               ActiveFedora::Reflection::OrdersReflection # map to :unordered_association in Wings::AttributeTransformer (but retain order)
            next
          when ActiveFedora::Reflection::DirectlyContainsOneReflection
            attribute_name = (reflection_key.to_s.singularize + '_id').to_sym
            type = ::Valkyrie::Types::ID.optional
          when ActiveFedora::Reflection::DirectlyContainsReflection,
               ActiveFedora::Reflection::IndirectlyContainsReflection
            attribute_name = (reflection_key.to_s.singularize + '_ids').to_sym
            type = ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
          when ActiveFedora::Reflection::SingularRDFPropertyReflection
            attribute_name = reflection.name.to_sym
            type = ::Valkyrie::Types::ID.optional
          when ActiveFedora::Reflection::RDFPropertyReflection
            attribute_name = reflection.name.to_sym
            type = ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
          else
            raise NotImplementedError, "Expected a known ActiveFedora::Reflection, but got #{reflection}"
          end

          attribute(attribute_name, type)
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
