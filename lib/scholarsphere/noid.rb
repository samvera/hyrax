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

module Scholarsphere
  module Noid
    def Noid.noidify(identifier)
      identifier.split(":").last
    end

    def Noid.namespaceize(identifier)
      if identifier.start_with?(Noid.namespace)
        identifier
      else
        "#{Noid.namespace}:#{identifier}"
      end
    end

    def noid
      Noid.noidify(self.pid)
    end

    def normalize_identifier
      params[:id] = Noid.namespaceize(params[:id])
    end

    protected
    def Noid.namespace
      Rails.application.config.id_namespace
    end
  end
end
