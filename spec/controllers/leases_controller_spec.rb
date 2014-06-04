require 'spec_helper'

describe LeasesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:a_work) { FactoryGirl.create(:generic_work, user: user) }
  let(:not_my_work) { FactoryGirl.create(:generic_work) }

  before { sign_in user }

  describe "#index" do
    context "when I am NOT a repository manager" do
      it "should redirect" do
        get :index
        expect(response).to redirect_to root_path
      end
    end
    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it "should show me the page" do
        get :index
        expect(response).to be_success
      end
    end
  end

  describe "#edit" do
    context "when I do not have edit permissions for the object" do
      it "should redirect" do
        get :edit, id: not_my_work
        expect(response.status).to eq 401
        expect(response).to render_template :unauthorized
      end
    end
    context "when I have permission to edit the object" do
      it "should show me the page" do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
  end



  describe "#destroy" do
    context "when I do not have edit permissions for the object" do
      it "should deny access" do
        get :destroy, id: not_my_work
        expect(response.status).to eq 401
        expect(response).to render_template :unauthorized
      end
    end
    context "when I have permission to edit the object" do
      before do
        expect(ActiveFedora::Base).to receive(:find).with(a_work.pid).and_return(a_work)
      end
      it "should deactivate lease and redirect" do
        expect(a_work).to receive(:deactivate_lease!)
        expect(a_work).to receive(:save)
        get :destroy, id: a_work
        expect(response).to redirect_to edit_lease_path(a_work)
      end
    end
  end
end
