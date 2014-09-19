require 'spec_helper'

describe TransfersController do
  describe "with a signed in user" do
    let(:another_user) { FactoryGirl.find_or_create(:jill) }
    let(:user) { FactoryGirl.find_or_create(:archivist) }

    before do
      sign_in user
    end

    describe "#index" do
      let!(:incoming_file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(another_user.user_key)
          f.save!
          f.request_transfer_to(user)
        end
      end
      let!(:outgoing_file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
          f.request_transfer_to(another_user)
        end
      end

      it "is successful" do
        get :index
        expect(response).to be_success
        assigns[:incoming].first.should be_kind_of ProxyDepositRequest
        assigns[:incoming].first.pid.should == incoming_file.pid
        assigns[:outgoing].first.should be_kind_of ProxyDepositRequest
        assigns[:outgoing].first.pid.should == outgoing_file.pid
      end

      describe "When the incoming request is for a deleted file" do
        before do
          incoming_file.destroy
        end
        it "should not show that file" do
          get :index
          response.should be_success
          assigns[:incoming].should be_empty
        end
      end
    end

    describe "#new" do
      let(:file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
        end
      end
      context 'when user is the depositor' do
        it "should be successful" do
          sign_in user
          get :new, id: file
          response.should be_success
          assigns[:generic_file].should == file
          assigns[:proxy_deposit_request].should be_kind_of ProxyDepositRequest
          assigns[:proxy_deposit_request].pid.should == file.pid
        end
      end
    end

    describe "#create" do
      let(:file) do
        GenericFile.new.tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save!
        end
      end
      it "should be successful" do
        User.any_instance.stub(:display_name).and_return("Jill Z. User")
        lambda {
          post :create, id: file.id, proxy_deposit_request: {transfer_to: another_user.user_key}
        }.should change(ProxyDepositRequest, :count).by(1)
        response.should redirect_to @routes.url_helpers.transfers_path
        flash[:notice].should == 'Transfer request created'
        proxy_request = another_user.proxy_deposit_requests.first
        proxy_request.pid.should == file.pid
        proxy_request.sending_user.should == user
        # AND A NOTIFICATION SHOULD HAVE BEEN CREATED
        notification = another_user.reload.mailbox.inbox[0].messages[0]
        notification.subject.should == "Ownership Change Request"
        notification.body.should == "<a href=\"/users/#{user.user_key}\">#{user.name}</a> wants to transfer a file to you. Review all <a href=\"#{@routes.url_helpers.transfers_path}\">transfer requests</a>"
      end
      it "should give an error if the user is not found" do
        lambda {
          post :create, id: file.id, proxy_deposit_request: {transfer_to: 'foo' }
        }.should_not change(ProxyDepositRequest, :count)
        assigns[:proxy_deposit_request].errors[:transfer_to].should == ['must be an existing user']
        response.should redirect_to(root_path)
      end
    end

    describe "#accept" do
      context "when I am the receiver" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should be successful when retaining access rights" do
          put :accept, id: user.proxy_deposit_requests.first
          response.should redirect_to @routes.url_helpers.transfers_path
          flash[:notice].should == "Transfer complete"
          assigns[:proxy_deposit_request].status.should == 'accepted'
          incoming_file.reload.edit_users.should == [another_user.user_key, user.user_key]
        end
        it "should be successful when resetting access rights" do
          put :accept, id: user.proxy_deposit_requests.first, reset: true
          response.should redirect_to @routes.url_helpers.transfers_path
          flash[:notice].should == "Transfer complete"
          assigns[:proxy_deposit_request].status.should == 'accepted'
          incoming_file.reload.edit_users.should == [user.user_key]
        end
        it "should handle sticky requests " do
          put :accept, id: user.proxy_deposit_requests.first, sticky: true
          response.should redirect_to @routes.url_helpers.transfers_path
          flash[:notice].should == "Transfer complete"
          assigns[:proxy_deposit_request].status.should == 'accepted'
          user.can_receive_deposits_from.should include(another_user)
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should not allow me" do
          put :accept, id: another_user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end

    describe "#reject" do
      context "when I am the receiver" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should be successful" do
          put :reject, id: user.proxy_deposit_requests.first
          response.should redirect_to @routes.url_helpers.transfers_path
          flash[:notice].should == "Transfer rejected"
          assigns[:proxy_deposit_request].status.should == 'rejected'
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should not allow me" do
          put :reject, id: another_user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end

    describe "#destroy" do
      context "when I am the sender" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(user.user_key)
            f.save!
            f.request_transfer_to(another_user)
          end
        end
        it "should be successful" do
          delete :destroy, id: another_user.proxy_deposit_requests.first
          response.should redirect_to @routes.url_helpers.transfers_path
          flash[:notice].should == "Transfer canceled"
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
            f.request_transfer_to(user)
          end
        end
        it "should not allow me" do
          delete :destroy, id: user.proxy_deposit_requests.first
          response.should redirect_to root_path
          flash[:alert].should == "You are not authorized to access this page."
        end
      end
    end
  end
end
