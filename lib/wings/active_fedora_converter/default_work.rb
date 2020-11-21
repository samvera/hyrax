# frozen_string_literal: true

module Wings
  class ActiveFedoraConverter
    ##
    # default work class builder
    def self.DefaultWork(resource_class) # rubocop:disable Naming/MethodName
      class_cache[resource_class] ||= Class.new(DefaultWork) do
        self.valkyrie_class = resource_class

        # extract AF properties from the Valkyrie schema;
        # skip reserved attributes, proctected properties, and those already defined
        resource_class.schema.each do |schema_key|
          next if resource_class.reserved_attributes.include?(schema_key.name)
          next if protected_property_name?(schema_key.name)
          next if properties.keys.include?(schema_key.name.to_s)

          property schema_key.name, predicate: RDF::URI("http://hyrax.samvera.org/ns/wings##{schema_key.name}")
        end

        # nested attributes in AF don't inherit! this needs to be here until we can drop it completely.
        accepts_nested_attributes_for :nested_resource
      end
    end

    ##
    # A base model class for valkyrie resources that don't have corresponding
    # ActiveFedora::Base models.
    class DefaultWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: "Wings::ActiveFedoraConverter::NestedResource"

      class_attribute :valkyrie_class
      self.valkyrie_class = Hyrax::Resource

      class << self
        delegate :human_readable_type, to: :valkyrie_class

        def model_name(*)
          _hyrax_default_name_class.new(valkyrie_class)
        end

        def to_rdf_representation
          "Wings(#{valkyrie_class})"
        end
        alias inspect to_rdf_representation
        alias to_s inspect
      end

      def to_global_id
        GlobalID.create(valkyrie_class.new(id: id))
      end
    end
  end
end
