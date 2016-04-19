require 'spec_helper'

describe CurationConcerns::SingleUseLinksController, type: :controller do
  routes { CurationConcerns::Engine.routes }
  let(:user) { create(:user) }

  let(:file) do
    FileSet.create do |file|
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
        post 'create_download', id: file
        expect(response).to be_success
        expect(response.body).to eq download_single_use_link_url(hash)
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do
        post 'create_show', id: file
        expect(response).to be_success
        expect(response.body).to eq show_single_use_link_url(hash)
      end
    end
  end

  describe "logged in user without edit permission" do
    before do
      @other_user = create(:user)
      file.read_users << @other_user
      file.save!
      sign_in @other_user
      file.read_users << @other_user
      file.save!
    end

    describe "GET 'download'" do
      it "and_return http success" do
        post 'create_download', id: file
        expect(response).not_to be_success
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do
        post 'create_show', id: file
        expect(response).not_to be_success
      end
    end
  end

  describe "unknown user" do
    describe "GET 'download'" do
      it "and_return http failure" do
        post 'create_download', id: file
        expect(response).not_to be_success
      end
    end

    describe "GET 'show'" do
      it "and_return http failure" do
        post 'create_show', id: file
        expect(response).not_to be_success
      end
    end
  end
end
