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

require "rake"

def loaded_files_excluding_current_rake_file
  $".reject { |file| file.include? "lib/tasks/fixtures" }
end

def activefedora_path
  Gem.loaded_specs['active-fedora'].full_gem_path
end

Given /^I load sufia fixtures$/ do
  @rake = Rake::Application.new
  Rake.application = @rake
    Rake.application.rake_require("tasks/sufia-fixtures", ["."], loaded_files_excluding_current_rake_file)
    Rake.application.rake_require("lib/tasks/fixtures", ["."], loaded_files_excluding_current_rake_file)
    Rake.application.rake_require("lib/tasks/active_fedora", [activefedora_path], loaded_files_excluding_current_rake_file)
  Rake::Task.define_task(:environment)
  @rake['sufia:fixtures:refresh'].invoke
  @rake['sufia:fixtures:fix'].invoke
end

