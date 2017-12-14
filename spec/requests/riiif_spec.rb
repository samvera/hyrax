RSpec.describe 'IIIF image API', type: :request do
  let(:user) { create(:user) }
  let(:size) { '300,' }

  let(:file_set) do
    create_for_repository(:file_set,
                          user: user,
                          content: file)
  end
  let(:file) { fixture_file_upload('/world.png', 'image/png') }
  let(:file_node_id) { file_set.member_ids.first }
  let(:work) do
    create_for_repository(:work, user: user, member_ids: [file_set.id])
  end

  describe 'GET /images/:id' do
    context "when the user is authorized" do
      it "returns an image" do
        login_as user
        get Riiif::Engine.routes.url_helpers.image_path(file_node_id, size: size)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq 'image/jpeg'
      end
    end

    context "when the user is not authorized" do
      it "returns an image" do
        get Riiif::Engine.routes.url_helpers.image_path(file_node_id, size: size)
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/jpeg'
      end
    end
  end
end
