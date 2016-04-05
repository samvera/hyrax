module CurationConcerns
  module Permissions
    module Readable
      extend ActiveSupport::Concern
      def public?
        read_groups.include?('public')
      end

      def registered?
        read_groups.include?('registered')
      end

      def private?
        !(public? || registered?)
      end
    end
  end
end
