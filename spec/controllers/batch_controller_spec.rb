require 'spec_helper'

describe BatchController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end
  describe "#update" do
    let(:batch_update_message) { double('batch update message') }
    let(:batch) { Batch.create }
    context "enquing a batch job" do
      before do
        allow(BatchUpdateJob).to receive(:new).with(user.user_key,
                                                    hash_including('generic_file' => anything)).
                                                    and_return(batch_update_message)
      end
      it "should be successful" do
        expect(Sufia.queue).to receive(:push).with(batch_update_message).once
        post :update, id: batch.id, "generic_file" => {"read_groups_string" => "", "read_users_string" => "archivist1, archivist2", "tag" => [""]}
        expect(response).to redirect_to routes.url_helpers.dashboard_files_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when user has edit permissions on a file" do
      # TODO all these tests could move to batch_update_job_spec.rb
      let!(:file) do
        GenericFile.new(batch: batch).tap do |f|
          f.apply_depositor_metadata(user)
          f.save!
        end
      end

      it "should set the groups" do
        post :update, id: batch, "generic_file"=>{"permissions_attributes"=>[{"type" => "group", "name" => "public", "access" => "read"}]}
        file.reload
        expect(file.read_groups).to include "public"
        expect(response).to redirect_to routes.url_helpers.dashboard_files_path
      end

      it "should set the users with read access" do
        post :update, id: batch, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1, archivist2", "tag"=>[""]}

        expect(file.reload.read_users).to eq ['archivist1', 'archivist2']
        expect(response).to redirect_to routes.url_helpers.dashboard_files_path
      end

      it "should set the groups with read access" do
        post :update, id: batch, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        expect(file.reload.read_groups).to eq ['group1', 'group2']
      end

      it "should set public read access" do
        post :update, id: batch, "visibility"=>"open", "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"", "tag"=>[""]}
        expect(file.reload.read_groups).to eq ['public']
      end

      it "should set public read access and groups at the same time" do
        post :update, id: batch, "visibility"=>"open", "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        expect(file.reload.read_groups).to eq ['group1', 'group2', 'public']
      end

      it "should set public discover access and groups at the same time" do
        post :update, id: batch, "permission"=>{"group"=>{"public"=>"none"}}, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file.reload
        expect(file.read_groups).to eq ['group1', 'group2']
        expect(file.discover_groups).to eq []
      end

      it "should set metadata like title" do
        post :update, id: batch, "generic_file"=>{"tag"=>["footag", "bartag"]}, "title"=>{file.id=>["New Title"]}
        file.reload
        expect(file.title).to eq ["New Title"]
        # TODO is order important?
        expect(file.tag).to include("footag", "bartag")
      end

      it "should not set any tags" do
        post :update, id: batch, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1", "tag"=>[""]}
        expect(file.reload.tag).to be_empty
      end
    end

    describe "when user does not have edit permissions on a file" do
      # TODO all these tests could move to batch_update_job_spec.rb
      let(:file) do
        GenericFile.new(batch: batch, title: ['Original Title']).tap do |f|
          f.apply_depositor_metadata('someone_else')
          f.save!
        end
      end

      it "should not modify the object" do
        post :update, id: batch, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}, "title"=>{file.id=>"Title Wont Change"}
        file.reload
        expect(file.title).to eq ["Original Title"]
        expect(file.read_groups).to eq []
      end
    end
  end
  describe "#edit" do
    before do
      allow_any_instance_of(User).to receive(:display_name).and_return("Jill Z. User")
      @b1 = Batch.new
      @b1.save
      @file = GenericFile.new(batch: @b1, label: 'f1')
      @file.apply_depositor_metadata(user)
      @file.save
      @file2 = GenericFile.new(batch: @b1, label: 'f2')
      @file2.apply_depositor_metadata(user)
      @file2.save
    end
    it "should default creator" do
      get :edit, id: @b1.id
      expect(assigns[:generic_file].creator[0]).to eq user.display_name
      expect(assigns[:generic_file].title[0]).to eq 'f1'
    end
  end
end
