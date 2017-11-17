module Hyrax
  class EmbargoIndexer
    def initialize(resource:)
      @resource = resource
    end

    # @return [Hash] the embargo values to add to the solr document
    def to_solr
      return {} unless acceptable_type?
      embargo = Hyrax::Queries.find_by(id: @resource.embargo_id)
      {}.tap do |doc|
        date_field_name = Hydra.config.permissions.embargo.release_date.sub(/_dtsi/, '')
        Solrizer.insert_field(doc, date_field_name, embargo.embargo_release_date, :stored_sortable)
        doc[::Solrizer.solr_name("visibility_during_embargo", :symbol)] = embargo.visibility_during_embargo if embargo.visibility_during_embargo
        doc[::Solrizer.solr_name("visibility_after_embargo", :symbol)] = embargo.visibility_after_embargo if embargo.visibility_after_embargo
        doc[::Solrizer.solr_name("embargo_history", :symbol)] = embargo.embargo_history if embargo.embargo_history
      end
    end

    private

      attr_reader :resource

      # allow objects that have embargo_id
      def acceptable_type?
        @resource.respond_to?(:embargo_id) && @resource.embargo_id
      end
  end
end
