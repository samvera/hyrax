require 'spec_helper'

describe SingleUseLinksController, :type => :controller do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:file) do
    GenericFile.create do |file|
      file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      file.apply_depositor_metadata(user)
    end
  end

  describe "logged in user with edit permission" do
    let(:hash) { "some-dummy-sha2-hash" }

    before do
      sign_in user
      allow(DateTime).to receive(:now).and_return(DateTime.now)
      expect(Digest::SHA2).to receive(:new).and_return(hash)
    end

    describe "GET 'download'" do
      it "and_return http success" do
        get 'new_download', id: file
        expect(response).to be_success
        expect(assigns[:link]).to eq routes.url_helpers.download_single_use_link_path(hash)
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'new_show', id: file
        expect(response).to be_success
        expect(assigns[:link]).to eq routes.url_helpers.show_single_use_link_path(hash)
      end
    end
  end

  describe "logged in user without edit permission" do
    before do
      @other_user = FactoryGirl.find_or_create(:archivist)
      file.read_users << @other_user
      file.save
      sign_in @other_user
      file.read_users << @other_user
      file.save
    end

    describe "GET 'download'" do
      it "and_return http success" do
        get 'new_download', id: file
        expect(response).not_to be_success
      end

    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'new_show', id: file
        expect(response).not_to be_success
      end

    end
  end

  describe "unknown user" do
    describe "GET 'download'" do
      it "and_return http failure" do
        get 'new_download', id: file
        expect(response).not_to be_success
      end
    end

    describe "GET 'show'" do
      it "and_return http failure" do
        get 'new_show', id: file
        expect(response).not_to be_success
      end
    end
  end
end
