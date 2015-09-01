require 'spec_helper'

describe BatchController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:other_user) { FactoryGirl.find_or_create(:curator) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe "#update" do
    let(:batch_update_message) { double('batch update message') }
    let(:batch) { Batch.create }
    context "when successful" do
      it "enqueues a batch job and redirects to generic_works list with a flash message" do
        expect(BatchUpdateJob).to receive(:perform_later).with(user.user_key, batch.id, { '1' => 'foo' },
                                                               { tag: [] }, 'open').once
        post :update, id: batch.id, title: { '1' => 'foo' }, visibility: 'open', generic_file: { tag: [""] }
        expect(response).to redirect_to routes.url_helpers.curation_concerns_generic_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when user has edit permissions on a file" do
      # TODO: all these tests could move to batch_update_job_spec.rb
      let!(:file) { GenericFile.create(batch: batch) { |f| f.apply_depositor_metadata(user) } }

      it "they can set permissions groups" do
        post :update, id: batch, "generic_file" => { "permissions_attributes" => [{ "type" => "group", "name" => "public", "access" => "read" }] }
        file.reload
        expect(file.read_groups).to include "public"
        expect(response).to redirect_to routes.url_helpers.curation_concerns_generic_works_path
      end

      it "they can set public read access" do
        post :update, id: batch, visibility: "open", generic_file: { tag: [""] }
        expect(file.reload.read_groups).to eq ['public']
      end

      it "they can set metadata like title" do
        post :update, id: batch, generic_file: { tag: ["footag", "bartag"] }, title: { file.id => ["New Title"] }
        file.reload
        expect(file.title).to eq ["New Title"]
        # TODO: is order important?
        expect(file.tag).to include("footag", "bartag")
      end

      it "they cannot set any tags" do
        post :update, id: batch, generic_file: { tag: [""] }
        expect(file.reload.tag).to be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      # TODO: all these tests could move to batch_update_job_spec.rb
      let(:file) do
        GenericFile.new(batch: batch, title: ['Original Title']).tap do |f|
          f.apply_depositor_metadata('someone_else')
          f.save!
        end
      end

      it "they cannot modify the object" do
        post :update, id: batch, "generic_file" => { "read_groups_string" => "group1, group2", "read_users_string" => "", "tag" => [""] }, "title" => { file.id => "Title Wont Change" }
        file.reload
        expect(file.title).to eq ["Original Title"]
        expect(file.read_groups).to eq []
      end
    end
  end

  describe "#edit" do
    let(:b1) { Batch.create }
    let!(:file) { GenericFile.create(batch: b1, label: 'f1') { |f| f.apply_depositor_metadata(user) } }
    let!(:file2) { GenericFile.create(batch: b1, label: 'f2') { |f| f.apply_depositor_metadata(user) } }

    it "sets up attributes for the form" do
      get :edit, id: b1
      expect(assigns[:form]).not_to be_persisted
      expect(assigns[:form].creator[0]).to eq user.user_key
      expect(assigns[:form].title[0]).to eq 'f1'
    end
  end
end
