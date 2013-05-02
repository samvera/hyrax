# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ChecksumAuditLog < ActiveRecord::Base
  attr_accessible :pass, :pid, :dsid, :version, :created_at

  def ChecksumAuditLog.get_audit_log(version)
    log = ChecksumAuditLog.find_or_create_by_pid_and_dsid_and_version(:pid => version.pid,
                                                                      :dsid => version.dsid,
                                                                      :version => version.versionID)
    log
  end

  def ChecksumAuditLog.prune_history(version)
    ## Check to see if there are previous passing logs that we can delete
    # we want to keep the first passing event after a failure, the most current passing event, and all failures so that this table doesn't grow too large
    # Simple way (a little naieve): if the last 2 were passing, delete the first one
    logs = GenericFile.load_instance_from_solr(version.pid).logs(version.dsid)
    list = logs.limit(2)
    if list.size > 1 && (list[0].pass == 1) && (list[1].pass == 1)
      list[0].delete
    end
  end
end
