# frozen_string_literal: true
module Hyrax
  module Permissions
    module Readable
      extend ActiveSupport::Concern
      def public?
        read_groups.include?(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
      end

      def registered?
        read_groups.include?(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED)
      end

      def private?
        !(public? || registered?)
      end
    end
  end
end
