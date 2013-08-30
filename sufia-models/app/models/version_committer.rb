class VersionCommitter < ActiveRecord::Base
  deprecated_attr_accessible  :obj_id, :datastream_id, :version_id, :committer_login
end
