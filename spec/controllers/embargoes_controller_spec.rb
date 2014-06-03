require 'spec_helper'

describe EmbargoesController do
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
        expect(response.status).to eq 404
        #response.should render_template(:unauthorized)
      end
    end
    context "when I am the owner of the object" do
      it "should show me the page" do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it "should show me the page" do
        get :edit, id: not_my_work
        expect(response).to be_success
      end
    end
  end



  describe "#destroy" do
    context "when I do not have edit permissions for the object" do
      it "should deny access" do
        get :destroy, id: not_my_work
        expect(response.status).to eq 404
      end
    end
    context "when I am the owner of the object" do
      it "should deactivate embargo and redirect" do
        get :destroy, id: a_work
        expect(controller.curation_concern).to receive(:deactivate_embargo!)
        expect(controller.curation_concern).to receive(:save)
        expect(response).to redirect_to :edit
      end
    end
    context "when I am a repository manager" do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it "should deactivate embargo and redirect" do
        get :destroy, id: not_my_work
        expect(controller.curation_concern).to receive(:deactivate_embargo!)
        expect(controller.curation_concern).to receive(:save)
        expect(response).to redirect_to :edit
      end
    end
  end

end