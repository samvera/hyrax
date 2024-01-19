# frozen_string_literal: true

module Wings
  class ActiveFedoraConverter
    def self.apply_properties(klass, schema)
      schema.each { |schema_key| PropertyApplicator.new(schema_key).apply(klass) }
    end

    ##
    # Constructs an ActiveFedora property from a Dry::Types schema key. This applicator
    # is intended to handle details like assocation types, where needed.
    #
    # @example
    #   MyValkyrieResource.schema.each do |schema_key|
    #     PropertyApplicator.new(schema_key).apply(MyActiveFedoraClass)
    #   end
    class PropertyApplicator
      ##
      # @param [Dry::Types::Schema::Key] key
      def initialize(key)
        @key = key
      end

      ##
      # @note this method is a silent no-op if the property is already defined
      #   or is a protected property on the target class
      #
      # @return [void] apply the property
      def apply(klass)
        return if klass.properties.keys.include?(name.to_s) ||
                  klass.protected_property_name?(name)
        klass.send(definition_method, name, options)
      end

      ##
      # @return [Symbol] the method name for property/association definition
      def definition_method
        return :ordered_aggregation if @key.name == :member_ids
        return :indirectly_contains if @key.name == :member_of_collection_ids
        :property
      end

      ##
      # @return [Symbol]
      def name
        return :members if @key.name == :member_ids
        return :member_of_collections if @key.name == :member_of_collection_ids
        @key.name
      end

      ##
      # @return [Hash<Symbol, Object>]
      def options
        return { has_member_relation: predicate, class_name: 'ActiveFedora::Base', through: :list_source } if
          @key.name == :member_ids

        if @key.name == :member_of_collection_ids
          return { has_member_relation: predicate, class_name: 'ActiveFedora::Base',
                   inserted_content_relation: RDF::Vocab::ORE.proxyFor, through: 'ActiveFedora::Aggregation::Proxy',
                   foreign_key: :target }
        end

        { predicate: predicate }
      end

      ##
      # @return [RDF::URI]
      def predicate
        return Hydra::PCDM::Vocab::PCDMTerms.hasMember if @key.name == :member_ids
        return Hydra::PCDM::Vocab::PCDMTerms.memberOf if @key.name == :member_of_collection_ids

        RDF::URI.intern("http://hyrax.samvera.org/ns/wings##{name}")
      end
    end

    ##
    # default work class builder
    def self.DefaultWork(resource_class) # rubocop:disable Naming/MethodName
      class_cache[resource_class] ||= Class.new(DefaultWork) do
        self.valkyrie_class = resource_class.respond_to?(:valkyrie_class) ? resource_class.valkyrie_class : resource_class
        # skip reserved attributes, we assume we don't need to translate valkyrie internals
        schema = valkyrie_class.schema.reject do |key|
          valkyrie_class.reserved_attributes.include?(key.name)
        end

        Wings::ActiveFedoraConverter.apply_properties(self, schema)

        # nested attributes in AF don't inherit! this needs to be here until we can drop it completely.y
        accepts_nested_attributes_for :nested_resource
      end
    end

    ##
    # A base model class for valkyrie resources that don't have corresponding
    # ActiveFedora::Base models.
    class DefaultWork < ActiveFedora::Base
      include Hyrax::Noid
      include Hyrax::Permissions
      include Hydra::AccessControls::Embargoable
      include Hyrax::CoreMetadata
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: "Wings::ActiveFedoraConverter::NestedResource"

      validates :lease_expiration_date, 'hydra/future_date': true, on: :create
      validates :embargo_release_date, 'hydra/future_date': true, on: :create

      class_attribute :valkyrie_class
      self.valkyrie_class = Hyrax::Resource

      class << self
        delegate :human_readable_type, to: :valkyrie_class

        def _to_partial_path
          "hyrax/#{valkyrie_class.model_name.collection}/#{valkyrie_class.model_name.element}"
        end

        def model_name(*)
          Hyrax::Name.new(valkyrie_class)
        end

        def to_rdf_representation
          "Wings(#{valkyrie_class})" unless valkyrie_class&.to_s&.include?('Wings(')
        end
        alias inspect to_rdf_representation
        alias to_s inspect
      end

      ##
      # Override aggressive Hydra::AccessControls validation
      def enforce_future_date_for_embargo?
        false
      end

      ##
      # Override aggressive Hydra::AccessControls validation
      def enforce_future_date_for_lease?
        false
      end

      def file_sets
        members.select(&:file_set?)
      end

      def indexing_service
        Hyrax::Indexers::ResourceIndexer.for(resource: valkyrie_resource)
      end

      def to_global_id
        GlobalID.create(valkyrie_class.new(id: id))
      end
    end
  end
end
