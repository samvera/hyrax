module Sufia
  module GenericFile
    module Visibility
      extend ActiveSupport::Concern
      extend Deprecation

      def visibility=(value)
        return if value.nil?
        # only set explicit permissions
        case value
        when Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          public_visibility!
        when Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          registered_visibility!
        when Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          private_visibility!
        else
          raise ArgumentError, "Invalid visibility: #{value.inspect}"
        end
      end

      def visibility
        if read_groups.include? Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
          Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        elsif read_groups.include? Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
          Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        else
          Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      def set_visibility(visibility)
        Deprecation.warn Visibility, "set_visibility is deprecated, use visibility= instead.  set_visibility will be removed in sufia 3.0", caller
        self.visibility= visibility
      end

      def visibility_changed?
        @visibility_will_change
      end

      private
      def visibility_will_change!
        @visibility_will_change = true
      end

      def public_visibility!
        visibility_will_change! unless visibility == Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        self.datastreams["rightsMetadata"].permissions({:group=>Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "read")
      end

      def registered_visibility!
        visibility_will_change! unless visibility == Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        self.datastreams["rightsMetadata"].permissions({:group=>Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "read")
        self.datastreams["rightsMetadata"].permissions({:group=>Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end

      def private_visibility!
        visibility_will_change! unless visibility == Sufia::Models::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        self.datastreams["rightsMetadata"].permissions({:group=>Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}, "none")
        self.datastreams["rightsMetadata"].permissions({:group=>Sufia::Models::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}, "none")
      end

    end
  end
end
