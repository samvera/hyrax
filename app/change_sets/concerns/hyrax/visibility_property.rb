# frozen_string_literal: true

module Hyrax
  # A base mixin for resources that hold files
  module VisibilityProperty
    extend ActiveSupport::Concern

    included do
      # override this property to define a different default
      property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility=(visibility)
      super.tap do |_result|
        case visibility
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
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        remove_groups.each { |group| read_groups.delete(group) }
        read_groups << AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
      end

      def registered_visibility!
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
        remove_groups.each { |group| read_groups.delete(group) }
        read_groups << AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
      end

      def private_visibility!
        represented_visibility.each { |group| read_groups.delete(group) }
      end
  end
end
