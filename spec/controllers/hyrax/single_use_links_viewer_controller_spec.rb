# frozen_string_literal: true
RSpec.describe Hyrax::SingleUseLinksViewerController do
  routes { Hyrax::Engine.routes }
  let(:user) { build(:user) }
  let(:file) do
    Hyrax.query_service.find_by(id: work.member_ids.first)
  end
  let(:file_metadata) { Hyrax.custom_queries.find_file_metadata_by(id: file.original_file_id) }
  let(:disk_file) { Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier) }
  let(:work) do
    FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)])
  end

  describe "retrieval links" do
    let :show_link do
      SingleUseLink.create item_id: file.id, path: Rails.application.routes.url_helpers.hyrax_file_set_path(id: file, locale: 'en')
    end

    let :download_link do
      SingleUseLink.create item_id: file.id, path: Hyrax::Engine.routes.url_helpers.download_path(id: file.id.to_s, locale: 'en')
    end

    let(:show_link_hash) { show_link.download_key }
    let(:download_link_hash) { download_link.download_key }

    describe "GET 'download'" do
      let(:expected_content) { disk_file.read }
      it "downloads the file and deletes the link from the database" do
        expect(controller).to receive(:send_file_headers!).with({ filename: 'image.jp2', disposition: 'attachment', type: file_metadata.mime_type })
        get :download, params: { id: download_link_hash }
        expect(response.body).to eq expected_content
        expect(response).to be_successful
        expect { SingleUseLink.find_by_download_key!(download_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_download_key!(download_link_hash).destroy }

        it "returns 404" do
          get :download, params: { id: download_link_hash }
          expect(response).to render_template("hyrax/single_use_links_viewer/single_use_error", "layouts/error")
        end
      end
    end

    describe "GET 'show'" do
      it "renders the file set's show page and deletes the link from the database" do
        get 'show', params: { id: show_link_hash }
        expect(response).to be_successful
        expect(assigns[:presenter].id).to eq file.id
        expect { SingleUseLink.find_by_download_key!(show_link_hash) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "when the key is not found" do
        before { SingleUseLink.find_by_download_key!(show_link_hash).destroy }
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

    describe "#current_ability" do
      context "when the key is not found" do
        before { SingleUseLink.find_by_download_key!(show_link_hash).destroy }

        it "returns the current ability" do
          expect(subject.send(:current_ability)).to be_present
        end

        it "returns the current user" do
          expect(subject.send(:current_ability).current_user).to be_present
        end
      end
    end
  end
end
