module Hydra
  module AccessControls
    module Embargoable
      extend ActiveSupport::Concern
      include Hydra::AccessControls::WithAccessRight

      included do
        validates :lease_expiration_date, :'hydra/future_date' => true, if: :enforce_future_date_for_lease?
        validates :embargo_release_date, :'hydra/future_date' => true, if: :enforce_future_date_for_embargo?

        belongs_to :embargo, predicate: Hydra::ACL.hasEmbargo, class_name: 'Hydra::AccessControls::Embargo'
        belongs_to :lease, predicate: Hydra::ACL.hasLease, class_name: 'Hydra::AccessControls::Lease'

        delegate :visibility_during_embargo, :visibility_during_embargo=, :visibility_after_embargo, :visibility_after_embargo=, :embargo_release_date, :embargo_release_date=, :embargo_history, :embargo_history=, to: :existing_or_new_embargo
        delegate :visibility_during_lease, :visibility_during_lease=, :visibility_after_lease, :visibility_after_lease=, :lease_expiration_date, :lease_expiration_date=, :lease_history, :lease_history=, to: :existing_or_new_lease
      end

      def enforce_future_date_for_lease?
        lease
      end

      def enforce_future_date_for_embargo?
        embargo
      end

      # if the embargo exists return it, if not, build one and return it
      def existing_or_new_embargo
        embargo || build_embargo
      end

      # if the lease exists return it, if not, build one and return it
      def existing_or_new_lease
        lease || build_lease
      end

      def to_solr(solr_doc = {})
        super.tap do |doc|
          doc.merge!(embargo_indexer_class.new(embargo).generate_solr_document) if embargo
          doc.merge!(lease_indexer_class.new(lease).generate_solr_document) if lease
        end
      end

      def embargo_indexer_class
        EmbargoIndexer
      end

      def lease_indexer_class
        LeaseIndexer
      end

      def under_embargo?
        embargo && embargo.active?
      end

      def active_lease?
        lease && lease.active?
      end


      # If changing away from embargo or lease, this will deactivate the lease/embargo before proceeding.
      # The lease_visibility! and embargo_visibility! methods rely on this to deactivate the lease when applicable.
      def visibility=(value)
        # If changing from embargo or lease, deactivate the lease/embargo and wipe out the associated metadata before proceeding
        deactivate_embargo! if deactivate_embargo?(value)
        deactivate_lease! if deactivate_lease?(value)
        super
      end

      def apply_embargo(release_date, visibility_during=nil, visibility_after=nil)
        self.embargo_release_date = release_date
        self.visibility_during_embargo = visibility_during unless visibility_during.nil?
        self.visibility_after_embargo = visibility_after unless visibility_after.nil?
        embargo_visibility!
        visibility_will_change! if embargo.changed?
      end

      # Deactivates the embargo and logs a message to the embargo object.
      # Marks this record as dirty so that it will get reindexed.
      def deactivate_embargo!
        embargo && embargo.deactivate!
        visibility_will_change!
      end

      # Validate that the current visibility is what is specified in the embargo
      def validate_visibility_complies_with_embargo
        return true unless embargo_release_date
        if under_embargo?
          expected_visibility = visibility_during_embargo
          failure_message = "An embargo is in effect for this object until #{embargo_release_date}.  Until that time the "
        else
          expected_visibility = visibility_after_embargo
          failure_message = "The embargo expired on #{embargo_release_date}.  The "
        end
        if visibility != expected_visibility
          failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call embargo_visibility! on this object to repair."
          self.errors[:embargo] << failure_message
          return false
        end
        true
      end

      # Set the current visibility to match what is described in the embargo.
      def embargo_visibility!
        return unless embargo_release_date
        if under_embargo?
          self.visibility_during_embargo = visibility_during_embargo ? visibility_during_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          self.visibility_after_embargo = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          self.visibility = visibility_during_embargo
        else
          self.visibility = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        end
      end

      def validate_visibility_complies_with_lease
        return true unless lease_expiration_date
        if active_lease?
          expected_visibility = visibility_during_lease
          failure_message = "A lease is in effect for this object until #{lease_expiration_date}.  Until that time the "
        else
          expected_visibility = visibility_after_lease
          failure_message = "The lease expired on #{lease_expiration_date}.  The "
        end
        if visibility != expected_visibility
          failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call lease_visibility! on this object to repair."
          self.errors[:lease] << failure_message
          return false
        end
        true
      end

      def apply_lease(release_date, visibility_during=nil, visibility_after=nil)
        self.lease_expiration_date = release_date
        self.visibility_during_lease = visibility_during unless visibility_during.nil?
        self.visibility_after_lease = visibility_after unless visibility_after.nil?
        lease_visibility!
        visibility_will_change! if lease.changed?
      end

      def deactivate_lease!
        lease && lease.deactivate!
        visibility_will_change!
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

      private

        # @return [true, false] true if there is an embargo set up and the visibility will change
        def deactivate_embargo?(value)
          embargo && embargo.embargo_release_date && value != embargo.visibility_during_embargo
        end

        # @return [true, false] true if there is a lease set up and the visibility will change
        def deactivate_lease?(value)
          lease && lease.lease_expiration_date && value != lease.visibility_during_lease
        end

    end
  end
end
