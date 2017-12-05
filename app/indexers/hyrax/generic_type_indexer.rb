module Hyrax
  class GenericTypeIndexer
    class_attribute :generic_type_field
    self.generic_type_field = :generic_type_sim # facetable

    def initialize(resource:)
      @resource = resource
    end

    # Makes Admin Sets, Works and Collections show under the dashboard tab
    # @return [Hash] the solr document with the generic_type field
    def to_solr
      generic_type
    end

    private

      attr_reader :resource

      # Choose the appropriate generic_type label for the resource
      # @return [Hash] hash containing the generic_type_field and value, if set, {} if not
      def generic_type
        if resource.is_a?(AdminSet) # must be first as doesn't have a falsey method for collection
          { generic_type_field => 'Admin Set' }
        elsif resource.collection?
          { generic_type_field => 'Collection' }
        elsif resource.work?
          { generic_type_field => 'Work' }
        else
          {}
        end
      # resources without collection? and work? methods will error, catch and return an empty hash
      rescue NoMethodError
        {}
      end
  end
end
