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

describe MailboxController do
  before(:each) do
    @user = FactoryGirl.find_or_create(:user)
    @another_user = FactoryGirl.find_or_create(:archivist)
    @message = "Test Message"
    @subject = "Test Subject"
    @rec1 = @another_user.send_message(@user, @message, @subject)
    @rec2 = @user.send_message(@another_user, @message, @subject)
    MailboxController.any_instance.stubs(:authenticate_user!).returns(true)
    sign_in @user
  end
  after(:each) do
    @rec1.delete
    @rec2.delete
  end
  describe "#index" do
    render_views
    it "should show message" do
      @user.expects(:mark_as_read)
      get :index
      response.should be_success
      response.should_not redirect_to(root_path)
      response.body.should include('Test Message')
      response.body.should include('Test Subject')
    end
  end
  describe "#delete" do
    render_views
    it "should delete message" do
      rec = @another_user.send_message(@user, 'message 2', 'subject 2')
      @user.mailbox.inbox.count.should == 2
      get :index
      response.body.should include('message 2')
      get :delete, :uid=> rec.conversation.id
      response.should redirect_to(@routes.url_helpers.mailbox_path)
      @user.mailbox.inbox.count.should ==1
    end
    it "should not delete message" do
      @curator = FactoryGirl.find_or_create(:curator)
      rec = @another_user.send_message(@curator, 'message 3', 'subject 3')
      @curator.mailbox.inbox.count.should == 1
      get :delete, :uid=> rec.conversation.id
      response.should redirect_to(@routes.url_helpers.mailbox_path)
      @curator.mailbox.inbox.count.should ==1
      rec.delete
      @curator.delete       
    end
  end
  describe "#delete_all" do
    render_views
    it "should delete message" do
      rec1 = @another_user.send_message(@user, 'message 2', 'subject 2')
      rec2 = @another_user.send_message(@user, 'message 3', 'subject 3')
      @user.mailbox.inbox.count.should == 3
      get :delete_all
      @user.mailbox.inbox.count.should == 0
    end
  end
end
