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

describe DashboardController do
  before do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    User.any_instance.stubs(:groups).returns([])
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  # This doesn't really belong here, but it works for now
  describe "authenticate!" do
    # move to scholarsphere
    # before(:each) do
    #   @user = FactoryGirl.find_or_create(:archivist)
    #   request.stubs(:headers).returns('REMOTE_USER' => @user.login).at_least_once
    #   @strategy = Devise::Strategies::HttpHeaderAuthenticatable.new(nil)
    #   @strategy.expects(:request).returns(request).at_least_once
    # end
    # after(:each) do
    #   @user.delete
    # end
    it "should populate LDAP attrs if user is new" do
      pending "This should only be in scholarsphere"
      User.stubs(:find_by_login).with(@user.login).returns(nil)
      User.expects(:create).with(login: @user.login).returns(@user).once
      User.any_instance.expects(:populate_attributes).once
      @strategy.should be_valid
      @strategy.authenticate!.should == :success
      sign_in @user
      get :index
    end
    it "should not populate LDAP attrs if user is not new" do
      pending "This should only be in scholarsphere"
      User.stubs(:find_by_login).with(@user.login).returns(@user)
      User.expects(:create).with(login: @user.login).never
      User.any_instance.expects(:populate_attributes).never
      @strategy.should be_valid
      @strategy.authenticate!.should == :success
      sign_in @user
      get :index
    end
  end
  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
      User.any_instance.stubs(:groups).returns([])
    end
    describe "#index" do
      before (:each) do
        xhr :get, :index
      end
      it "should be a success" do
        response.should be_success
        response.should render_template('dashboard/index')
      end
      it "should return an array of documents I can edit" do
        @user_results = Blacklight.solr.get "select", :params=>{:fq=>["edit_access_group_t:public OR edit_access_person_t:#{@user.user_key}"]}
        assigns(:document_list).count.should eql(@user_results["response"]["numFound"])
      end
    end
  end
  describe "not logged in as a user" do
    describe "#index" do
      it "should return an error" do
        xhr :post, :index
        response.should_not be_success
      end
    end
  end
end
