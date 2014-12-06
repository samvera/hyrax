module Sufia
  module FileContent
    module Versions
      extend ActiveSupport::Concern

      included do
        has_many_versions
      end

      def latest_version
        versions.last.label unless versions.empty?
      end

      def version_committer(version)
        vc = VersionCommitter.where(version_id: version)
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
