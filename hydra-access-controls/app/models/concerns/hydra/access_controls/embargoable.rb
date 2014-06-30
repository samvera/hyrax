module Hydra
  module AccessControls
    module Embargoable
      extend ActiveSupport::Concern
      include Hydra::AccessControls::WithAccessRight

      included do
        validates :embargo_release_date, :lease_expiration_date, :'hydra/future_date' => true

        has_attributes :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
          :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
          datastream: 'rightsMetadata', multiple: false

        has_attributes :embargo_history, :lease_history, datastream: 'rightsMetadata', multiple:true
      end

      def under_embargo?
        rightsMetadata.under_embargo?
      end

      def active_lease?
        rightsMetadata.active_lease?
      end

      # If changing away from embargo or lease, this will deactivate the lease/embargo before proceeding.
      # The lease_visibility! and embargo_visibility! methods rely on this to deactivate the lease when applicable.
      def visibility=(value)
        # If changing from embargo or lease, deactivate the lease/embargo and wipe out the associated metadata before proceeding
        if !embargo_release_date.nil?
          deactivate_embargo! unless value == visibility_during_embargo
        end
        if !lease_expiration_date.nil?
          deactivate_lease! unless value == visibility_during_lease
        end
        super
      end

      def apply_embargo(release_date, visibility_during=nil, visibility_after=nil)
        self.embargo_release_date = release_date
        self.visibility_during_embargo = visibility_during unless visibility_during.nil?
        self.visibility_after_embargo = visibility_after unless visibility_after.nil?
        embargo_visibility!
      end

      def deactivate_embargo!
        return unless embargo_release_date
        embargo_state = under_embargo? ? "active" : "expired"
        embargo_record = embargo_history_message(embargo_state, Date.today, embargo_release_date, visibility_during_embargo, visibility_after_embargo)
        self.embargo_release_date = nil
        self.visibility_during_embargo = nil
        self.visibility_after_embargo = nil
        self.embargo_history += [embargo_record]
      end

      def validate_embargo
        if embargo_release_date
          if under_embargo?
            expected_visibility = visibility_during_embargo
            failure_message = "An embargo is in effect for this object until #{embargo_release_date}.  Until that time the "
          else
            expected_visibility = visibility_after_embargo
            failure_message = "The embargo expired on #{embargo_release_date}.  The "
          end
          if visibility == expected_visibility
            return true
          else
            failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call embargo_visibility! on this object to repair."
            self.errors[:embargo] << failure_message
            return false
          end
        else
          return true
        end
      end

      # Set the current visibility to match what is described in the embargo.
      def embargo_visibility!
        if embargo_release_date
          if under_embargo?
            self.visibility_during_embargo = visibility_during_embargo ? visibility_during_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
            self.visibility_after_embargo = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            self.visibility = visibility_during_embargo
          else
            self.visibility = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          end
        end
      end

      def validate_lease
        if lease_expiration_date
          if active_lease?
            expected_visibility = visibility_during_lease
            failure_message = "A lease is in effect for this object until #{lease_expiration_date}.  Until that time the "
          else
            expected_visibility = visibility_after_lease
            failure_message = "The lease expired on #{lease_expiration_date}.  The "
          end
          if visibility == expected_visibility
            return true
          else
            failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call lease_visibility! on this object to repair."
            self.errors[:lease] << failure_message
            return false
          end
        else
          return true
        end
      end

      def apply_lease(release_date, visibility_during=nil, visibility_after=nil)
        self.lease_expiration_date = release_date
        self.visibility_during_lease = visibility_during unless visibility_during.nil?
        self.visibility_after_lease = visibility_after unless visibility_after.nil?
        self.lease_visibility!
      end

      def deactivate_lease!
        return unless lease_expiration_date
        lease_state = active_lease? ? "active" : "expired"
        lease_record = lease_history_message(lease_state, Date.today, lease_expiration_date, visibility_during_lease, visibility_after_lease)
        self.lease_expiration_date = nil
        self.visibility_during_lease = nil
        self.visibility_after_lease = nil
        self.lease_history += [lease_record]
      end

      # Set the current visibility to match what is described in the lease.
      def lease_visibility!
        if lease_expiration_date
          if active_lease?
            self.visibility_during_lease = visibility_during_lease ? visibility_during_lease : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
            self.visibility_after_lease = visibility_after_lease ? visibility_after_lease : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
            self.visibility = visibility_during_lease
          else
            self.visibility = visibility_after_lease ? visibility_after_lease : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          end
        end
      end

      protected

        # Create the log message used when deactivating an embargo
        # This method may be overriden in order to transform the values of the passed parameters.
        def embargo_history_message(state, deactivate_date, release_date, visibility_during, visibility_after)
          I18n.t 'hydra.embargo.history_message', state: state, deactivate_date: deactivate_date, release_date: release_date,
            visibility_during: visibility_during, visibility_after: visibility_after
        end

        # Create the log message used when deactivating a lease
        # This method may be overriden in order to transform the values of the passed parameters.
        def lease_history_message(state, deactivate_date, expiration_date, visibility_during, visibility_after)
          I18n.t 'hydra.lease.history_message', state: state, deactivate_date: deactivate_date, expiration_date: expiration_date,
            visibility_during: visibility_during, visibility_after: visibility_after
        end
    end
  end
end
