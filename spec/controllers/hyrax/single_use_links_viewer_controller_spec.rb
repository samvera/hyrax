RSpec.describe Hyrax::SingleUseLinksViewerController do
  routes { Hyrax::Engine.routes }

  let(:user) { build(:user) }
  let :show_link do
    SingleUseLink.create itemId: file.id, path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file, locale: 'en')
  end
  let(:content) { fixture_file_upload('/world.png', 'image/png') }
  let(:file) do
    create_for_repository(:file_set, label: 'world.png', user: user, content: content)
  end
  let :download_link do
    SingleUseLink.create itemId: file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: file, locale: 'en')
  end
  let(:show_link_hash) { show_link.downloadKey }
  let(:download_link_hash) { download_link.downloadKey }

  describe "GET 'download'" do
    let(:expected_content) { content.tempfile.read }

    it "downloads the file and deletes the link from the database" do
      expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'attachment', type: 'image/png')
      get :download, params: { id: download_link_hash }
      expect(response.body).to eq expected_content
      expect(response).to be_success
      expect { SingleUseLink.find_by_downloadKey!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when the key is not found" do
      before { SingleUseLink.find_by_downloadKey!(download_link_hash).destroy }

      it "returns 404" do
        get :download, params: { id: download_link_hash }
        expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
      end
    end
  end

  describe "GET 'show'" do
    it "renders the file set's show page and deletes the link from the database" do
      get 'show', params: { id: show_link_hash }
      expect(response).to be_success
      expect(assigns[:presenter].id).to eq file.id.to_s
      expect { SingleUseLink.find_by_downloadKey!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when the key is not found" do
      before { SingleUseLink.find_by_downloadKey!(show_link_hash).destroy }
      it "returns 404" do
        get :show, params: { id: show_link_hash }
        expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
      end
    end

    it "returns 404 on attempt to get show path with download hash" do
      get :show, params: { id: download_link_hash }
      expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
    end
  end
end
