module Hyrax
  class HumanReadableTypeIndexer
    def initialize(resource:)
      @resource = resource
    end

    # Write the human_readable_type into the solr_document
    # @return [Hash] solr_document the solr document with the human_readable_type
    def to_solr
      return {} if resource.human_readable_type.blank?
      {
        human_readable_type_tesim: resource.human_readable_type,
        human_readable_type_sim: resource.human_readable_type
      }
    end

    private

      attr_reader :resource
  end
end
