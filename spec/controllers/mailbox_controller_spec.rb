require 'spec_helper'

describe MailboxController do
  before(:each) do
    @user = FactoryGirl.find_or_create(:jill)
    @another_user = FactoryGirl.find_or_create(:archivist)
    @message = "Test Message"
    @subject = "Test Subject"
    @rec1 = @another_user.send_message(@user, @message, @subject)
    @rec2 = @user.send_message(@another_user, @message, @subject)
    MailboxController.any_instance.stub(:authenticate_user!).and_return(true)
    sign_in @user
  end
  after(:each) do
    @rec1.delete
    @rec2.delete
  end
  describe "#index" do
    it "should show message" do
      get :index
      response.should be_success
      assigns[:messages].first.last_message.body.should == 'Test Message'
      assigns[:messages].first.last_message.subject.should == 'Test Subject'
      @user.mailbox.inbox(unread: true).count.should == 0
    end
  end
  describe "#delete" do
    it "should delete message" do
      rec = @another_user.send_message(@user, 'message 2', 'subject 2')
      expect {
        delete :destroy, id: rec.conversation.id
        response.should redirect_to(@routes.url_helpers.notifications_path)
      }.to change {@user.mailbox.inbox.count}.by(-1)
    end
    it "should not delete message" do
      @curator = FactoryGirl.find_or_create(:curator)
      rec = @another_user.send_message(@curator, 'message 3', 'subject 3')
      expect {
        delete :destroy, id: rec.conversation.id
        response.should redirect_to(@routes.url_helpers.notifications_path)
      }.to_not change { @curator.mailbox.inbox.count}
    end
  end
  describe "#delete_all" do
    it "should delete message" do
      rec1 = @another_user.send_message(@user, 'message 2', 'subject 2')
      rec2 = @another_user.send_message(@user, 'message 3', 'subject 3')
      @user.mailbox.inbox.count.should == 3
      get :delete_all
      @user.mailbox.inbox.count.should == 0
    end
  end
end
