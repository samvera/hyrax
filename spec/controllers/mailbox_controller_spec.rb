require 'spec_helper'

describe MailboxController do
  before(:each) do
    @user = FactoryGirl.find_or_create(:user)
    @another_user = FactoryGirl.find_or_create(:archivist)
    @message = "Test Message"
    @subject = "Test Subject"
    @rec1 = @another_user.send_message(@user, @message, @subject)
    @rec2 = @user.send_message(@another_user, @message, @subject)
    User.stubs(:current).returns( @user)
    MailboxController.any_instance.stubs(:authenticate_user!).returns(true)
    sign_in @user
    User.current = @user
  end
  after(:each) do
    @rec1.delete
    @rec2.delete
  end
  describe "#index" do
    render_views
    it "should show message" do
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
      response.should redirect_to(mailbox_path)
      @user.mailbox.inbox.count.should ==1
    end
    it "should not delete message" do
      @curator = FactoryGirl.find_or_create(:curator)
      rec = @another_user.send_message(@curator, 'message 3', 'subject 3')
      @curator.mailbox.inbox.count.should == 1
      get :delete, :uid=> rec.conversation.id
      response.should redirect_to(mailbox_path)
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
