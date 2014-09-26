module Hydra
  module AccessControls
    module Visibility
      extend ActiveSupport::Concern

      def visibility=(value)
        return if value.nil?
        # only set explicit permissions
        case value
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          public_visibility!
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          registered_visibility!
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          private_visibility!
        else
          raise ArgumentError, "Invalid visibility: #{value.inspect}"
        end
      end

      def visibility
        if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        else
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      def visibility_changed?
        !!@visibility_will_change
      end

      private
      def visibility_will_change!
        @visibility_will_change = true
      end

      def public_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        self.datastreams["rightsMetadata"].permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "read")
      end

      def registered_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        self.datastreams["rightsMetadata"].permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "read")
        self.datastreams["rightsMetadata"].permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end

      def private_visibility!
        visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        self.datastreams["rightsMetadata"].permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "none")
        self.datastreams["rightsMetadata"].permissions({:group=>Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end

    end
  end
end
