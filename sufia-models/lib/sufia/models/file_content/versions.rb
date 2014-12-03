module Sufia
  module FileContent
    module Versions
      extend ActiveSupport::Concern

      included do
        has_many_versions
      end

      def version_label uri
        uri.split("/").last
      end

      def latest_version
        version_label(versions.last) unless versions.empty?
      end

      def version_committer(version)
        vc = VersionCommitter.where(version_id: version_label(version))
        return vc.empty? ? nil : vc.first.committer_login
      end

      def save
        super.tap do |passing|
          create_version if passing
        end
      end
      
    end
  end
end
