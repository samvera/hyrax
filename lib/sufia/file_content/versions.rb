module Sufia
  module FileContent
    module Versions
      def get_version(version_id)
        self.versions.select { |v| v.versionID == version_id}.first
      end

      def latest_version
        self.versions.first
      end

      def version_committer(version)
        vc = VersionCommitter.where(:obj_id => version.pid,
                                    :datastream_id => version.dsid,
                                    :version_id => version.versionID)
        return vc.empty? ? nil : vc.first.committer_login
      end


    end
  end
end

