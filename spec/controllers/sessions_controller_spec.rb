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

require 'spec_helper'

describe SessionsController do
  describe "routing" do
    it "should send /logout to sessions#destroy" do
      { get: '/logout' }.should route_to(controller: 'sessions', action: 'destroy')
      destroy_user_session_path.should == '/logout'
    end
    it "should send /login to sessions#new" do
      { get: '/login' }.should route_to(controller: 'sessions', action: 'new')
      new_user_session_path.should == '/login'
    end
  end
  describe "#destroy" do
    it "should redirect to the central logout page and destroy the cookie" do
      request.env['COSIGN_SERVICE'] = 'cosign-gamma-ci.dlt.psu.edu'
      cookies.expects(:delete).with('cosign-gamma-ci.dlt.psu.edu')
      get :destroy
      response.should redirect_to Sufia::Engine.config.logout_url
    end
  end
  describe "#new" do
    it "should redirect to the central login page" do
      get :new
      response.should redirect_to Sufia::Engine.config.login_url
    end
  end
end
