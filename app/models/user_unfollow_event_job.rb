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

class UserUnfollowEventJob < EventJob
  def initialize(unfollower_id, unfollowee_id)
    action = "User #{link_to_profile unfollower_id} has unfollowed #{link_to_profile unfollowee_id}"
    timestamp = Time.now.to_i
    unfollower = User.find_by_user_key(unfollower_id)
    # Create the event
    event = unfollower.create_event(action, timestamp)
    # Log the event to the unfollower's stream
    unfollower.log_event(event)
    # Fan out the event to unfollowee
    unfollowee = User.find_by_user_key(unfollowee_id)
    unfollowee.log_event(event)
    # Fan out the event to all followers
    unfollower.followers.each do |user|
      user.log_event(event)
    end
  end
end
