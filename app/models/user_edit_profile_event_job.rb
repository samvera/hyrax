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

class UserEditProfileEventJob < EventJob
  def initialize(editor_id)
    action = "User #{link_to_profile editor_id} has edited his or her profile"
    timestamp = Time.now.to_i
    editor = User.find_by_user_key(editor_id)
    # Create the event
    event = editor.create_event(action, timestamp)
    # Log the event to the editor's stream
    editor.log_event(event)
    # Fan out the event to all followers
    editor.followers.each do |user|
      user.log_event(event)
    end
  end
end
