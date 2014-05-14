module Sufia
  module GenericFile
    module Versions
      def record_version_committer(user)
        version = content.latest_version
        # content datastream not (yet?) present
        return if version.nil?
        VersionCommitter.create(:obj_id => version.pid,
                                :datastream_id => version.dsid,
                                :version_id => version.versionID,
                                :committer_login => user.user_key)
      end

    end
  end
end
