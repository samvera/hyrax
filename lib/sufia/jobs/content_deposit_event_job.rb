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

class ContentDepositEventJob < EventJob
  def run
    gf = GenericFile.find(generic_file_id)
    action = "User #{link_to_profile depositor_id} has deposited #{link_to gf.title.first, Sufia::Engine.routes.url_helpers.generic_file_path(gf.noid)}"
    timestamp = Time.now.to_i
    depositor = User.find_by_user_key(depositor_id)
    # Create the event
    event = depositor.create_event(action, timestamp)
    # Log the event to the depositor's profile stream
    depositor.log_profile_event(event)
    # Log the event to the GF's stream
    gf.log_event(event)
    # Fan out the event to all followers who have access
    depositor.followers.select { |user| user.can? :read, get_permissions_solr_response_for_doc_id(gf.pid)[1] }.each do |follower|
      follower.log_event(event)
    end
  end
end
