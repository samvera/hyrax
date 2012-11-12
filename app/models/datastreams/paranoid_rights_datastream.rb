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

require 'hydra/datastream/rights_metadata'
# subclass built-in Hydra RightsDatastream and build in extra model-level validation
class ParanoidRightsDatastream < Hydra::Datastream::RightsMetadata
  use_terminology Hydra::Datastream::RightsMetadata

  VALIDATIONS = [
    {:key => :edit_users, :message => 'Depositor must have edit access', :condition => lambda { |obj| !obj.edit_users.include?(obj.depositor) }},
    {:key => :edit_groups, :message => 'Public cannot have edit access', :condition => lambda { |obj| obj.edit_groups.include?('public') }},
    {:key => :edit_groups, :message => 'Registered cannot have edit access', :condition => lambda { |obj| obj.edit_groups.include?('registered') }}
  ]

  def validate(object)
    valid = true
    VALIDATIONS.each do |validation|
      if validation[:condition].call(object)
        object.errors[validation[:key]] ||= []
        object.errors[validation[:key]] << validation[:message]
        valid = false
      end
    end
    return valid
  end
end
