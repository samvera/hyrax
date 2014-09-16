module Sufia
  module FileContent
    module Versions
      extend ActiveSupport::Concern

      included do
        has_many_versions
      end

      def uuid_for(version_id)
        version_id.to_s.split("/").last
      end

      def latest_version
        versions.last
      end

      def root_version
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
