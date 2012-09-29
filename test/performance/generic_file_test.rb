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
require 'capybara/rails'

class GenericFileTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { :runs => 5, :metrics => [:wall_time, :memory]
  #                          :output => 'tmp/performance', :formats => [:flat] }
  fixtures :users

  def setup
    # Application requires logged-in user
    # login via https
    session = open_session
    session.post_via_redirect "/users/sign_in","commit"=>"Sign in", "user[email]" => 'test@example.com',
                                  "user[password]" => "password", "user[remember_me]" => "0", "utf8"=>"✓"
    session.assert_response(:success)
    session
  end

  def teardown
    get_via_redirect "/users/sign_out"
  end  
 
  def test_creating_new_post
     file = fixture_file_upload('spec/fixtures/world.png','image/png')     
     #post_via_redirect generic_files_path, :pid => 'test:789', :Filedata=>[file], :Filename=>"The world", :permission=>{"group"=>{"public"=>"discover"}}
     post_via_redirect generic_files_path, :pid => 'test:789', :files=>[file], :Filename=>"The world", :permission=>{"group"=>{"public"=>"discover"}}
     assert_response(:success)
  end

end
