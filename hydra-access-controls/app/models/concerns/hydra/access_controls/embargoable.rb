module Hydra
  module AccessControls
    module Embargoable
      extend ActiveSupport::Concern
      include Hydra::AccessControls::WithAccessRight

      included do
        validates :embargo_release_date, :'hydra/future_date' => true

        has_attributes :visibility_during_embargo, :visibility_after_embargo, 
          :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
          :embargo_release_date,
          datastream: 'rightsMetadata', multiple: false

        has_attributes :embargo_history, :lease_history, datastream: 'rightsMetadata', multiple:true
      end

      def under_embargo?
        @under_embargo ||= rightsMetadata.under_embargo?
      end

      def active_lease?
        @active_lease ||= rightsMetadata.active_lease?
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
        self.embargo_visibility!
      end

      def deactivate_embargo!
        embargo_state = under_embargo? ? "active" : "expired"
        embargo_record = "An #{embargo_state} embargo was deactivated on #{Date.today}.  Its release date was #{embargo_release_date}.  Visibility during embargo was #{visibility_during_embargo} and intended visibility after embargo was #{visibility_after_embargo}"
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
        lease_state = active_lease? ? "active" : "expired"
        lease_record = "An #{lease_state} lease was deactivated on #{Date.today}.  Its release date was #{lease_expiration_date}.  Visibility during the lease was #{visibility_during_lease} and intended visibility after lease was #{visibility_after_lease}."
        self.lease_expiration_date = nil
        self.visibility_during_lease = nil
        self.visibility_after_lease = nil
        self.lease_history += [lease_record]
      end

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

    end
  end
end
