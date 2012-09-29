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

require 'test_helper'
require 'rails/performance_test_help'

class GenericFileModelTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  self.profile_options = {:formats => [:call_tree]}
  def test_creation
    GenericFile.create
  end
  def test_new_then_save
    gf = GenericFile.new
    gf.save
  end
  def test_to_solr
    gf = GenericFile.create
    gf.to_solr
  end
end
