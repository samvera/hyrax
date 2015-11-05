require 'spec_helper'

describe UploadSetsController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:other_user) { FactoryGirl.find_or_create(:curator) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe "#update" do
    let(:batch_update_message) { double('batch update message') }
    let(:batch) { UploadSet.create }
    context "enquing a batch job" do
      before do
        allow(UploadSetUpdateJob).to receive(:new).with(user.user_key, batch.id, { '1' => 'foo' },
                                                    { tag: [] }, 'open').and_return(batch_update_message)
      end
      it "is successful" do
        expect(CurationConcerns.queue).to receive(:push).with(batch_update_message).once
        post :update, id: batch.id, title: { '1' => 'foo' }, visibility: 'open', file_set: { tag: [""] }
        expect(response).to redirect_to routes.url_helpers.dashboard_files_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when submiting works on behalf of another user" do
      let(:somebody_else_work) do
        GenericWork.create(title: ['Original Title'], on_behalf_of: other_user.user_key) do |w|
          w.apply_depositor_metadata(user)
        end
      end

      let(:somebody_else_file) do
        FileSet.new(title: ['Original Title']) do |f|
          f.apply_depositor_metadata(user)
        end
      end
      let(:batch) do
        UploadSet.create { |b| b.file_sets.push(somebody_else_file) }
      end

      before do
        Hydra::Works::AddFileSetToGenericWork.call(somebody_else_work, somebody_else_file)
        somebody_else_work.save
      end

      it "redirects to my shares page" do
        post :update, id: batch, file_set: { permissions_attributes: [{ type: "group", name: "public", access: "read" }] }
        expect(response).to redirect_to routes.url_helpers.dashboard_shares_path
      end
    end

    describe "when user has edit permissions on a file" do
      # TODO: all these tests could move to batch_update_job_spec.rb
      let!(:file) { FileSet.create(batch: batch) { |f| f.apply_depositor_metadata(user) } }

      it "sets the groups" do
        post :update, id: batch, "file_set" => { "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }] }
        file.reload
        expect(file.read_groups).to include "public"
        expect(response).to redirect_to routes.url_helpers.dashboard_files_path
      end

      it "sets public read access" do
        post :update, id: batch, visibility: "open", file_set: { tag: [""] }
        expect(file.reload.read_groups).to eq ['public']
      end

      it "sets metadata like title" do
        post :update, id: batch, file_set: { tag: ["footag", "bartag"] }, title: { file.id => ["New Title"] }
        file.reload
        expect(file.title).to eq ["New Title"]
        # TODO: is order important?
        expect(file.tag).to include("footag", "bartag")
      end

      it "does not set any tags" do
        post :update, id: batch, file_set: { tag: [""] }
        expect(file.reload.tag).to be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      # TODO: all these tests could move to batch_update_job_spec.rb
      let(:file) do
        FileSet.new(batch: batch, title: ['Original Title']).tap do |f|
          f.apply_depositor_metadata('someone_else')
          f.save!
        end
      end

      it "does not modify the object" do
        post :update, id: batch, "file_set" => { "read_groups_string" => "group1, group2", "read_users_string" => "", "tag" => [""] }, "title" => { file.id => "Title Wont Change" }
        file.reload
        expect(file.title).to eq ["Original Title"]
        expect(file.read_groups).to eq []
      end
    end
  end

  describe "#edit" do
    before do
      allow_any_instance_of(User).to receive(:display_name).and_return("Jill Z. User")
    end
    let(:b1) { UploadSet.create }
    let!(:file) { FileSet.create(batch: b1, label: 'f1') { |f| f.apply_depositor_metadata(user) } }
    let!(:file2) { FileSet.create(batch: b1, label: 'f2') { |f| f.apply_depositor_metadata(user) } }

    it "defaults creator" do
      get :edit, id: b1
      expect(assigns[:form]).not_to be_persisted
      expect(assigns[:form].creator[0]).to eq user.display_name
      expect(assigns[:form].title[0]).to eq 'f1'
    end
  end
end
