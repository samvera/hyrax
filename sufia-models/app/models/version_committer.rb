class VersionCommitter < ActiveRecord::Base
  attr_accessible :obj_id, :datastream_id, :version_id, :committer_login if Rails::VERSION::MAJOR == 3
end
