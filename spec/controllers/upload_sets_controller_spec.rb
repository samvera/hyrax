require 'spec_helper'

describe UploadSetsController do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  routes { Rails.application.routes }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe "#update" do
    let(:upload_set) { UploadSet.create }
    context "enquing a update job" do
      it "is successful" do
        expect(UploadSetUpdateJob).to receive(:perform_later).with(user.user_key,
                                                                   upload_set.id,
                                                                   { '1' => 'foo' },
                                                                   { tag: [] },
                                                                   'open')
        post :update, id: upload_set, title: { '1' => 'foo' },
                      visibility: 'open',
                      upload_set: { tag: [""] }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when submiting works on behalf of another user" do
      let!(:somebody_else_work) do
        GenericWork.create!(title: ['Original Title'], on_behalf_of: other_user.user_key, upload_set_id: upload_set.id) do |w|
          w.apply_depositor_metadata(user)
        end
      end

      it "redirects to my shares page" do
        post :update, id: upload_set, upload_set: { permissions_attributes: [{ type: "group", name: "public", access: "read" }] }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_shares_path
      end
    end

    describe "when user has edit permissions on a file" do
      # TODO: all these tests could move to upload_set_update_job_spec.rb
      let!(:work) { create(:work, upload_set: upload_set, user: user) }

      it "sets the groups" do
        post :update, id: upload_set, upload_set: { "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }] }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        work.reload
        expect(work.read_groups).to include "public"
      end

      it "sets public read access" do
        post :update, id: upload_set, visibility: "open", upload_set: { tag: [""] }
        expect(work.reload.read_groups).to eq ['public']
      end

      it "sets metadata like title" do
        post :update, id: upload_set, upload_set: { tag: ["footag", "bartag"] }, title: { work.id => ["New Title"] }
        work.reload
        expect(work.title).to eq ["New Title"]
        expect(work.tag).to include("footag", "bartag")
      end

      it "does not set any tags" do
        post :update, id: upload_set, upload_set: { tag: [""] }
        expect(work.reload.tag).to be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      # TODO: all these tests could move to upload_set_update_job_spec.rb
      let(:work) do
        GenericWork.create!(upload_set: upload_set, title: ['Original Title']) do |f|
          f.apply_depositor_metadata('someone_else')
        end
      end

      it "does not modify the object" do
        post :update, id: upload_set, upload_set: { "read_groups_string" => "group1, group2", "read_users_string" => "", "tag" => [""] }, "title" => { work.id => "Title Wont Change" }
        work.reload
        expect(work.title).to eq ["Original Title"]
        expect(work.read_groups).to eq []
      end
    end
  end

  describe "#edit" do
    let(:upload_set) { UploadSet.create }
    it "defaults creator" do
      get :edit, id: upload_set
      expect(assigns[:form]).to be_kind_of Sufia::UploadSetForm
      expect(assigns[:form].model).to eq upload_set
      expect(response).to be_success
    end
  end
end
