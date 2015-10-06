require 'spec_helper'

describe UploadSetsController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:other_user) { FactoryGirl.find_or_create(:curator) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe "#update" do
    let(:upload_set_update_message) { double('upload_set update message') }
    let(:upload_set) { UploadSet.create }
    context "when successful" do
      it "enqueues a upload_set job and redirects to generic_works list with a flash message" do
        expect(UploadSetUpdateJob).to receive(:perform_later).with(user.user_key, upload_set.id, { '1' => 'foo' },
                                                                   { tag: [] }, 'open').once
        post :update, id: upload_set.id, title: { '1' => 'foo' }, visibility: 'open', file_set: { tag: [""] }
        expect(response).to redirect_to routes.url_helpers.curation_concerns_generic_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when user has edit permissions on a file" do
      # TODO: all these tests could move to upload_set_update_job_spec.rb
      let!(:file) { FileSet.create(upload_set: upload_set) { |f| f.apply_depositor_metadata(user) } }

      it "they can set permissions groups" do
        post :update, id: upload_set, "file_set" => { "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }] }
        file.reload
        expect(file.read_groups).to include "public"
        expect(response).to redirect_to routes.url_helpers.curation_concerns_generic_works_path
      end

      it "they can set public read access" do
        post :update, id: upload_set, visibility: "open", file_set: { tag: [""] }
        expect(file.reload.read_groups).to eq ['public']
      end

      it "they can set metadata like title" do
        post :update, id: upload_set, file_set: { tag: ["footag", "bartag"] }, title: { file.id => ["New Title"] }
        file.reload
        expect(file.title).to eq ["New Title"]
        # TODO: is order important?
        expect(file.tag).to include("footag", "bartag")
      end

      it "they cannot set any tags" do
        post :update, id: upload_set, file_set: { tag: [""] }
        expect(file.reload.tag).to be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      # TODO: all these tests could move to upload_set_update_job_spec.rb
      let(:file) do
        FileSet.new(upload_set: upload_set, title: ['Original Title']) do |f|
          f.apply_depositor_metadata('someone_else')
          f.save!
        end
      end

      it "they cannot modify the object" do
        post :update, id: upload_set, "file_set" => { "read_groups_string" => "group1, group2", "read_users_string" => "", "tag" => [""] }, "title" => { file.id => "Title Wont Change" }
        file.reload
        expect(file.title).to eq ["Original Title"]
        expect(file.read_groups).to eq []
      end
    end
  end

  describe "#edit" do
    let(:us1) { UploadSet.create }
    let!(:file) { FileSet.create(upload_set: us1, label: 'f1') { |f| f.apply_depositor_metadata(user) } }
    let!(:file2) { FileSet.create(upload_set: us1, label: 'f2') { |f| f.apply_depositor_metadata(user) } }

    it "sets up attributes for the form" do
      get :edit, id: us1
      expect(assigns[:form]).not_to be_persisted
      expect(assigns[:form].creator[0]).to eq user.user_key
      expect(assigns[:form].title[0]).to eq 'f1'
    end
  end
end
