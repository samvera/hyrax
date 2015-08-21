module CurationConcerns
  module GenericFile
    module Versions
      @@count = 0
      def record_version_committer(user)
        version = latest_version
        # content datastream not (yet?) present
        return if version.nil?
        @@count += 1
        # raise "Recording #{@@count} #{version.uri} for #{user.user_key}" if @@count == 3
        VersionCommitter.create(version_id: version.uri, committer_login: user.user_key)
      end
    end
  end
end
