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
        a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        a_work.embargo_release_date = release_date.to_s
        a_work.save(validate: false)
        get :destroy, id: a_work
      end

      context "with an active embargo" do
        let(:release_date) { Date.today+2 }

        it "should deactivate embargo without updating visibility and redirect" do
          expect(a_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          expect(response).to redirect_to edit_embargo_path(a_work)
        end
      end

      context "with an expired embargo" do
        let(:release_date) { Date.today-2 }

        it "should deactivate embargo, update the visibility and redirect" do
          expect(a_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(response).to redirect_to confirm_curation_concern_permission_path(a_work)
        end
      end
    end
  end

  describe "#update" do
    context "when I have permission to edit the object" do
      let(:a_file) { FactoryGirl.build(:generic_file, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
      before do
        a_work.generic_files << a_file
        a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        a_work.embargo_release_date = release_date.to_s
        a_work.save(validate: false)
      end

      context "with an expired embargo" do
        let(:release_date) { Date.today-2 }
        it "should deactivate embargo, update the visibility and redirect" do
          patch :update, batch_document_ids: [a_work.pid], embargoes: { "0" => { copy_visibility: a_work.id} }
          expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(a_file.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(response).to redirect_to embargoes_path
        end
      end
    end
  end
end
