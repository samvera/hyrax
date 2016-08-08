module Hydra::AccessControls
  class Lease < ActiveFedora::Base
    property :visibility_during_lease, predicate: Hydra::ACL.visibilityDuringLease, multiple:false
    property :visibility_after_lease, predicate: Hydra::ACL.visibilityAfterLease, multiple:false
    property :lease_expiration_date, predicate: Hydra::ACL.leaseExpirationDate, multiple:false
    property :lease_history, predicate: Hydra::ACL.leaseHistory

    def lease_expiration_date=(date)
      date = DateTime.parse(date) if date.kind_of?(String)
      super(date)
    end

    def active?
      lease_expiration_date.present? && Date.today < lease_expiration_date
    end

    def deactivate!
      return unless lease_expiration_date
      lease_state = active? ? "active" : "expired"
      lease_record = lease_history_message(lease_state, Date.today, lease_expiration_date, visibility_during_lease, visibility_after_lease)
      self.lease_expiration_date = nil
      self.visibility_during_lease = nil
      self.visibility_after_lease = nil
      self.lease_history += [lease_record]
    end

    def to_hash
      {}.tap do |doc|
        date_field_name = Hydra.config.permissions.lease.expiration_date.sub(/_dtsi/, '')
        Solrizer.insert_field(doc, date_field_name, lease_expiration_date, :stored_sortable)

        doc[::Solrizer.solr_name("visibility_during_lease", :symbol)] = visibility_during_lease unless visibility_during_lease.nil?
        doc[::Solrizer.solr_name("visibility_after_lease", :symbol)] = visibility_after_lease unless visibility_after_lease.nil?
        doc[::Solrizer.solr_name("lease_history", :symbol)] = lease_history unless lease_history.nil?
      end
    end

    protected
      # Create the log message used when deactivating a lease
      # This method may be overriden in order to transform the values of the passed parameters.
      def lease_history_message(state, deactivate_date, expiration_date, visibility_during, visibility_after)
        I18n.t 'hydra.lease.history_message', state: state, deactivate_date: deactivate_date, expiration_date: expiration_date,
          visibility_during: visibility_during, visibility_after: visibility_after
      end
  end
end
