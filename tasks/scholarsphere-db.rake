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

namespace :scholarsphere do
  namespace :db do
    desc "delete all Generic Files in Fedora and Solr (This may take some time...)."
    task :deleteAll => :environment do
      unless Rails.env.integration?
        puts "Warning: this task is only for the integration environment!"
        next
      end
      GenericFile.find(:all, :rows => GenericFile.count).each(&:delete)
    end

    desc "delete 500 Generic Files from Fedora and Solr."
    task :delete500 => :environment do
      unless Rails.env.integration?
        puts "Warning: this task is only for the integration environment!"
        next
      end
      GenericFile.find(:all, :rows => 500).each(&:delete)
    end
  end
end
