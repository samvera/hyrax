module Hyrax
  # Models a lease for an object. This is where access is high until a point in
  # time when the lease expires and then the access becomes more restrictive.
  class Lease < Valkyrie::Resource
    attribute :id, Valkyrie::Types::ID.optional
    attribute :visibility_during_lease, Valkyrie::Types::SingleValuedString
    attribute :visibility_after_lease, Valkyrie::Types::SingleValuedString
    attribute :lease_expiration_date, Valkyrie::Types::Set.member(Valkyrie::Types::DateTime).optional
    attribute :lease_history, Valkyrie::Types::Set

    def active?
      (lease_expiration_date.present? && Time.zone.today < lease_expiration_date.first)
    end

    # Deactivates the lease by nullifying all properties and logging a message
    # to the lease_history property
    def deactivate
      return unless lease_expiration_date
      lease_state = active? ? "active" : "expired"
      lease_record = history_message(lease_state, Time.zone.today, lease_expiration_date, visibility_during_lease, visibility_after_lease)
      self.lease_expiration_date = nil
      self.visibility_during_lease = nil
      self.visibility_after_lease = nil
      self.lease_history += [lease_record]
    end

    private

      # Create the log message used when deactivating a lease
      # This method may be overriden in order to transform the values of the passed parameters.
      def history_message(state, deactivate_date, expiration_date, visibility_during, visibility_after)
        I18n.t 'hydra.lease.history_message', state: state, deactivate_date: deactivate_date, expiration_date: expiration_date,
                                              visibility_during: visibility_during, visibility_after: visibility_after
      end
  end
end
