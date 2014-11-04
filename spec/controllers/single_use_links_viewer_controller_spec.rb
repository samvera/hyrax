require 'spec_helper'

describe SingleUseLinksViewerController do
  let(:file) do
    GenericFile.new.tap do |file|
      file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      file.apply_depositor_metadata('mjg')
      file.save!
    end
  end

  after do
    SingleUseLink.delete_all
  end

  describe "retrieval links" do
    let :show_link do
      SingleUseLink.create itemId: file.id, path: routes.url_helpers.generic_file_path(id: file)
    end

    let :download_link do
      SingleUseLink.create itemId: file.id, path: routes.url_helpers.download_path(id: file)
    end

    let :show_link_hash do
      show_link.downloadKey
    end

    let :download_link_hash do
      download_link.downloadKey
    end

    describe "GET 'download'" do
      let(:expected_content) { ActiveFedora::Base.find(file.id).content.content }

      it "and_return http success" do
        expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'inline', type: 'image/png')
        get :download, id: download_link_hash
        expect(response.body).to eq expected_content
        expect(response).to be_success
      end

      it "and_return 404 on second attempt" do
        get :download, id: download_link_hash
        expect(response).to be_success
        get :download, id: download_link_hash
        expect(response).to render_template('error/single_use_error')
      end

      it "and_return 404 on attempt to get download with show" do
        get :download, id: download_link_hash
        expect(response).to be_success
        get :show, id:download_link_hash
        expect(response).to render_template('error/single_use_error')
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'show', id: show_link_hash
        expect(response).to be_success
        expect(assigns[:asset].id).to eq file.id
      end

      it "and_return 404 on second attempt" do
        get :show, id: show_link_hash
        expect(response).to be_success
        get :show, id: show_link_hash
        expect(response).to render_template('error/single_use_error')
      end
      it "and_return 404 on attempt to get show path with download hash" do
        get :show, id: download_link_hash
        expect(response).to render_template('error/single_use_error')
      end
    end
  end

end
