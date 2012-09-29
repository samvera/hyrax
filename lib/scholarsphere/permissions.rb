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

module ScholarSphere
  module GenericFile
    module Permissions
      # Copies and transforms permsisions set in params[:permission] into
      # params[:generic_file][:read_groups_string] and params[:generic_file][:discover_groups_string]
      # Once this is done it becomes possible to do:
      # @generic_file.update_attributes(params[:generic_file])
      # Which will set the permissions correctly
      def self.parse_permissions(params)
        if params.has_key?(:permission)
          if params[:permission][:group][:public] == 'read'
            if params[:generic_file][:read_groups_string].present?
              params[:generic_file][:read_groups_string] << ', public'
            else
              params[:generic_file][:read_groups_string] << 'public'
            end
          end
          if params[:permission][:group][:registered] == 'read'
            if params[:generic_file][:read_groups_string].present?
              params[:generic_file][:read_groups_string] << ', registered'
            else
              params[:generic_file][:read_groups_string] << 'registered'
            end
          end
        end
      end
    end
  end
end
