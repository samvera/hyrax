module CurationConcern
  module Embargoable
    extend ActiveSupport::Concern

    # Embargo is not a proper citizen in the sufia model. Hence the override.
    # Embargo, as implemented in HydraAccessControls, prevents something from
    # being seen until the release date, then is public.
    module VisibilityOverride
      def visibility= value
        if value == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
          super(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        else
          self.embargo_release_date = nil
          super(value)
        end
      end

      def visibility
        if read_groups.include?(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC) &&
          embargo_release_date
          return Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        end
        super
      end
    end

    include Hydra::AccessControls::WithAccessRight
    include VisibilityOverride

    included do
      validates :embargo_release_date, future_date: true
      before_save :write_embargo_release_date, prepend: true

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
      @embargo_release_date = begin
        value.present? ? value.to_date : nil
      rescue NoMethodError, ArgumentError
        value
      end
    end

    def embargo_release_date
      @embargo_release_date || rightsMetadata.embargo_release_date
    end

  end
end
