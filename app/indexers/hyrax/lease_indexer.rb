module Hyrax
  # Finds the keys/values used for indexing the Lease (if one exists) for a work
  class LeaseIndexer
    def initialize(resource:)
      @resource = resource
    end

    # @return [Hash] the lease values to add to the solr document
    def to_solr
      return {} unless acceptable_type?
      lease = Hyrax::Queries.find_by(id: @resource.lease_id)
      {}.tap do |doc|
        date_field_name = Hydra.config.permissions.lease.expiration_date.sub(/_dtsi/, '')
        Solrizer.insert_field(doc, date_field_name, lease.lease_expiration_date, :stored_sortable)

        doc[::Solrizer.solr_name("visibility_during_lease", :symbol)] = lease.visibility_during_lease if lease.visibility_during_lease
        doc[::Solrizer.solr_name("visibility_after_lease", :symbol)] = lease.visibility_after_lease if lease.visibility_after_lease
        doc[::Solrizer.solr_name("lease_history", :symbol)] = lease.lease_history if lease.lease_history
      end
    end

    private

      attr_reader :resource

      # allow objects that have lease_id
      def acceptable_type?
        @resource.respond_to?(:lease_id) && @resource.lease_id
      end
  end
end
