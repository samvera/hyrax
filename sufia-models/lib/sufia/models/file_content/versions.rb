module Sufia
  module FileContent
    module Versions
      extend ActiveSupport::Concern

      included do
        has_many_versions
      end

      def get_version(version_id)
        versions.select { |v| v.versionID == version_id}.first
      end

      def latest_version
        versions.first
      end

      def version_committer(version)
        vc = VersionCommitter.where(version_id: version.to_s)
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
