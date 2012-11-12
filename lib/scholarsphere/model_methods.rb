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

require 'hydra/model_methods'
module ScholarSphere
  module ModelMethods
    extend ActiveSupport::Concern
    include Hydra::ModelMethods

    # OVERRIDE to support Hydra::Datastream::Properties which does not
    #   respond to :depositor_values but :depositor
    # Adds metadata about the depositor to the asset
    # Most important behavior: if the asset has a rightsMetadata datastream, this method will add +depositor_id+ to its individual edit permissions.

    def apply_depositor_metadata(depositor_id)
      rights_ds = self.datastreams["rightsMetadata"]
      prop_ds = self.datastreams["properties"]

      rights_ds.update_indexed_attributes([:edit_access, :person]=>depositor_id) unless rights_ds.nil?
      prop_ds.depositor = depositor_id unless prop_ds.nil?

      return true
    end
  end
end
