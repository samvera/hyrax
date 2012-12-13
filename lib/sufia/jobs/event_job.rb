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

class EventJob
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include ActionView::Helpers::DateHelper
  include Hydra::AccessControlsEnforcement
  include SufiaHelper

  def queue_name
    :event
  end

  attr_accessor :generic_file_id, :depositor_id

  def initialize(generic_file_id, depositor_id)
    self.generic_file_id = generic_file_id
    self.depositor_id = depositor_id
  end

end
