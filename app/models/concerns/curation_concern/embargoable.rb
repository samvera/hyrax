module CurationConcern
  module Embargoable
    extend ActiveSupport::Concern

    # Embargo is not a proper citizen in the sufia model. Hence the override.
    # Embargo, as implemented in HydraAccessControls, prevents something from
    # being seen until the release date, then is public.
    #module VisibilityOverride
    #  def visibility= value
    #    if value == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
    #      super(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    #    else
    #      self.embargo_release_date = nil
    #      super(value)
    #    end
    #  end
    #
    #  def visibility
    #    if read_groups.include?(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC) && embargo_release_date
    #      return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
    #    end
    #    super
    #  end
    #end

    include Hydra::AccessControls::WithAccessRight
    #include VisibilityOverride

    included do
      validates :embargo_release_date, :'worthwhile/future_date' => true
      before_save :write_embargo_release_date, prepend: true

      has_attributes :visibility_during_embargo, datastream: 'rightsMetadata', :at=>[:embargo, :machine, :visibility_during], multiple:false
      has_attributes :visibility_after_embargo, datastream: 'rightsMetadata', :at=>[:embargo, :machine, :visibility_after], multiple:false
      has_attributes :visibility_during_lease, datastream: 'rightsMetadata', :at=>[:lease, :machine, :visibility_during], multiple:false
      has_attributes :visibility_after_lease, datastream: 'rightsMetadata', :at=>[:lease, :machine, :visibility_after], multiple:false
      has_attributes :lease_expiration_date, datastream: 'rightsMetadata', :at=>[:lease, :machine, :date], multiple:false


      # unless self.class.included_modules.include?('Hydra::AccessControls::Permissions')
        #   self.class.send(:include, Hydra::AccessControls::Permissions)
        # end
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
          failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call apply_embargo_visibility! on this object to repair."
          self.errors[:embargo] << failure_message
          return false
        end
      else
        return true
      end
    end

    def apply_embargo_visibility!
      if embargo_release_date
        if under_embargo?
          self.visibility = visibility_during_embargo ? visibility_during_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        else
          self.visibility = visibility_after_embargo ? visibility_after_embargo : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_RESTRICTED
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
          failure_message << "visibility should be #{expected_visibility} but it is currently #{visibility}.  Call apply_lease_visibility! on this object to repair."
          self.errors[:lease] << failure_message
          return false
        end
      else
        return true
      end
    end

    def apply_lease_visibility!
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
