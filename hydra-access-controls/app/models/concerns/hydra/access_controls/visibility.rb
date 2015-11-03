module Hydra::AccessControls
  module Visibility
    extend ActiveSupport::Concern

    def visibility=(value)
      return if value.nil?
      # only set explicit permissions
      case value
      when AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        public_visibility!
      when AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        registered_visibility!
      when AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        private_visibility!
      else
        raise ArgumentError, "Invalid visibility: #{value.inspect}"
      end
    end

    def visibility
      if read_groups.include? AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      elsif read_groups.include? AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      else
        AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end

    def visibility_changed?
      !!@visibility_will_change
    end

    private

      # Override represented_visibility if you want to add another visibility that is
      # represented as a read group (e.g. on-campus)
      # @return [Array] a list of visibility types that are represented as read groups
      def represented_visibility
        [AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
         AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end

      def visibility_will_change!
        @visibility_will_change = true
      end

      def public_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        set_read_groups([AccessRight::PERMISSION_TEXT_VALUE_PUBLIC], remove_groups)
      end

      def registered_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
        set_read_groups([AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED], remove_groups)
      end

      def private_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        set_read_groups([], represented_visibility)
      end
  end
end
