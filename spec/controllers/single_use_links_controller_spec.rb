require 'spec_helper'

describe SingleUseLinksController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:file) do
    GenericFile.new.tap do |f|
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata(user)
      f.save
    end
  end
  let(:file2) do
    GenericFile.new.tap do |f|
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata('mjg36')
      f.save
    end
  end
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
  end
  after(:all) do
    ActiveFedora::Base.destroy_all
    SingleUseLink.destroy_all
  end
  describe "logged in user with edit permission" do
    before do
      sign_in user
      @now = DateTime.now
      allow(DateTime).to receive(:now).and_return(@now)
      @hash = "some-dummy-sha2-hash"
      allow(Digest::SHA2).to receive(:new).and_return(@hash)
    end

    it "gets the download link" do
      get 'new_download', id: file.pid
      expect(response).to be_success
      expect(assigns[:link]).to eq @routes.url_helpers.download_single_use_link_path(@hash)
    end

    it "gets the show link" do
      get 'new_show', id: file.pid
      expect(response).to be_success
      expect(assigns[:link]).to eq @routes.url_helpers.show_single_use_link_path(@hash)
    end
  end

  describe "logged in user without edit permission" do
    before do
      @other_user = FactoryGirl.find_or_create(:archivist)
      sign_in @other_user
      file.read_users << @other_user
      file.save
    end

    describe "GET 'download'" do
      it "and_return http success" do
        get 'new_download', id: file.pid
        expect(response).not_to be_success
      end

    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'new_show', id: file.pid
        expect(response).not_to be_success
      end

    end
  end

  describe "unknown user" do
    describe "GET 'download'" do
      it "and_return http failure" do
        get 'new_download', id: file.pid
        expect(response).not_to be_success
      end
    end

    describe "GET 'show'" do
      it "and_return http failure" do
        get 'new_show', id: file.pid
        expect(response).not_to be_success
      end
    end
  end
end
