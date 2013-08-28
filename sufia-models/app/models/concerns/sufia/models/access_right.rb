module Sufia
  module Models
    class AccessRight
      PERMISSION_TEXT_VALUE_PUBLIC = 'public'.freeze
      PERMISSION_TEXT_VALUE_AUTHENTICATED = 'registered'.freeze
      VISIBILITY_TEXT_VALUE_PUBLIC = 'open'.freeze
      VISIBILITY_TEXT_VALUE_EMBARGO = 'open_with_embargo_release_date'.freeze
      VISIBILITY_TEXT_VALUE_AUTHENTICATED = 'psu'.freeze
      VISIBILITY_TEXT_VALUE_PRIVATE = 'restricted'.freeze

      # @param permissionable [#visibility, #permissions]
      # @example
      #   file = GenericFile.find('sufia:1234')
      #   access = Sufia::AccessRight.new(file)
      def initialize(permissionable)
        @permissionable = permissionable
      end

      attr_reader :permissionable
      delegate :persisted?, :permissions, :visibility, to: :permissionable
      protected :persisted?, :permissions, :visibility


      def open_access?
        return true if has_visibility_text_for?(VISIBILITY_TEXT_VALUE_PUBLIC)
        # We don't want to know if its under embargo, simply does it have a date.
        # In this way, we can properly inform the label input
        persisted_open_access_permission? && !permissionable.embargo_release_date.present?
      end

      def open_access_with_embargo_release_date?
        return false unless permissionable_is_embargoable?
        return true if has_visibility_text_for?(VISIBILITY_TEXT_VALUE_EMBARGO)
        # We don't want to know if its under embargo, simply does it have a date.
        # In this way, we can properly inform the label input
        persisted_open_access_permission? && permissionable.embargo_release_date.present?
      end

      def authenticated_only?
        return false if open_access?
        has_permission_text_for?(PERMISSION_TEXT_VALUE_AUTHENTICATED) ||
          has_visibility_text_for?(VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      end

      def private?
        return false if open_access?
        return false if authenticated_only?
        return false if open_access_with_embargo_release_date?
        true
      end

      private

        def persisted_open_access_permission?
          if persisted?
            has_permission_text_for?(PERMISSION_TEXT_VALUE_PUBLIC)
          else
            visibility.to_s == ''
          end
        end

        def on_or_after_any_embargo_release_date?
          return true unless permissionable.embargo_release_date
          permissionable.embargo_release_date.to_date < Date.today
        end

        def permissionable_is_embargoable?
          permissionable.respond_to?(:embargo_release_date)
        end

        def has_visibility_text_for?(text)
          visibility == text
        end
        def has_permission_text_for?(text)
          !!permissions.detect { |perm| perm[:name] == text }
        end
    end
  end
end
