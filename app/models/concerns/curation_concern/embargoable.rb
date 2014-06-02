module CurationConcern
  module Embargoable
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight

    included do
      validates :embargo_release_date, :'worthwhile/future_date' => true
      before_save :write_embargo_release_date, prepend: true

      has_attributes :visibility_during_embargo, datastream: 'rightsMetadata', :at=>[:embargo, :machine, :visibility_during], multiple:false
      has_attributes :visibility_after_embargo, datastream: 'rightsMetadata', :at=>[:embargo, :machine, :visibility_after], multiple:false
      has_attributes :visibility_during_lease, datastream: 'rightsMetadata', :at=>[:lease, :machine, :visibility_during], multiple:false
      has_attributes :visibility_after_lease, datastream: 'rightsMetadata', :at=>[:lease, :machine, :visibility_after], multiple:false
      has_attributes :lease_expiration_date, datastream: 'rightsMetadata', :at=>[:lease, :machine, :date], multiple:false
      has_attributes :embargo_history, datastream: 'rightsMetadata', :at=>[:embargo, :human_readable], multiple:true
      has_attributes :lease_history, datastream: 'rightsMetadata', :at=>[:lease, :human_readable], multiple:true

    end

    # If changing away from embargo or lease, this will deactivate the lease/embargo before proceeding.
    # The lease_visibility! and embargo_visibility! methods rely on this to deactivate the lease when applicable.
    def visibility=(value)
      # If changing from embargo or lease, deactivate the lease/embargo and wipe out the associated metadata before proceeding
      if !embargo_release_date.nil?
        deactivate_embargo! unless (value == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO || value == visibility_during_embargo )
      end
      if !lease_expiration_date.nil?
        deactivate_lease! unless (value == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE || value == visibility_during_lease )
      end
      begin
        super
      rescue ArgumentError => e
        case value
          when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
            if embargo_release_date.nil?
              raise ArgumentError, "To set visibility as #{value.inspect} you must also specify embargo_release_date."
            else
              embargo_visibility!
            end
          when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
            if lease_expiration_date.nil?
              raise ArgumentError, "To set visibility as #{value.inspect} you must also specify lease_expiration_date."
            else
              lease_visibility!
            end
          else
            raise e
        end
      end
    end

    def deactivate_embargo!
      embargo_state = under_embargo? ? "active" : "expired"
      embargo_record = "An #{embargo_state} embargo was deactivated on #{Date.today}.  Its release date was #{embargo_release_date}.  Visibility during embargo was #{visibility_during_embargo} and intended visibility after embargo was #{visibility_after_embargo}"
      self.embargo_release_date = nil
      self.visibility_during_embargo = nil
      self.visibility_after_embargo = nil
      self.embargo_history += [embargo_record]
    end

    def deactivate_lease!
      lease_state = under_embargo? ? "active" : "expired"
      lease_record = "An #{lease_state} lease was deactivated on #{Date.today}.  Its release date was #{lease_expiration_date}.  Visibility during embargo was #{visibility_during_lease} and intended visibility after embargo was #{visibility_after_lease}"
      self.lease_expiration_date = nil
      self.visibility_during_lease = nil
      self.visibility_after_lease = nil
      self.lease_history += [lease_record]
    end

    def write_embargo_release_date
      if defined?(@embargo_release_date)
        rightsMetadata.embargo_release_date = @embargo_release_date
      end
      true
    end
    protected :write_embargo_release_date

    def embargo_release_date=(value)
      @embargo_release_date = rightsMetadata.embargo_release_date = begin
        value.present? ? value.to_date : nil
      rescue NoMethodError, ArgumentError
        value
      end
    end

    def embargo_release_date
      @embargo_release_date || rightsMetadata.embargo_release_date
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
          self.visibility = visibility_during_embargo ? visibility_during_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        else
          self.visibility = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        end
      end
    end

    def validate_lease
      if lease_expiration_date
        if lease_expired?
          expected_visibility = visibility_after_lease
          failure_message = "The lease expired on #{lease_expiration_date}.  The "
        else
          expected_visibility = visibility_during_lease
          failure_message = "A lease is in effect for this object until #{lease_expiration_date}.  Until that time the "
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

    def lease_visibility!
      if lease_expiration_date
        if lease_expired?
          self.visibility = visibility_after_lease ? visibility_after_lease : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        else
          self.visibility = visibility_during_lease ? visibility_during_lease : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end
    end

  end
end
