module Hydra::AccessControls
  class Lease < ActiveFedora::Base
    property :visibility_during_lease, predicate: Hydra::ACL.visibilityDuringLease
    property :visibility_after_lease, predicate: Hydra::ACL.visibilityAfterLease
    property :lease_expiration_date, predicate: Hydra::ACL.leaseExpirationDate
    property :lease_history, predicate: Hydra::ACL.leaseHistory

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_during_lease_with_first
      visibility_during_lease_without_first.first
    end
    alias_method_chain :visibility_during_lease, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def visibility_after_lease_with_first
      visibility_after_lease_without_first.first
    end
    alias_method_chain :visibility_after_lease, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def lease_expiration_date_with_first
      lease_expiration_date_without_first.first
    end
    alias_method_chain :lease_expiration_date, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def lease_expiration_date_with_casting=(date)
      date = DateTime.parse(date) if date && date.kind_of?(String)
      self.lease_expiration_date_without_casting = date
    end
    alias_method_chain :lease_expiration_date=, :casting

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
