# frozen_string_literal: true
RSpec.describe 'IIIF image API', type: :request do
  let(:wings_disabled) { Hyrax.config.disable_wings }
  let(:user) { create(:user) }
  let(:uploaded_file) { create(:uploaded_file, file: File.open('spec/fixtures/world.png')) }
  let(:file_metadata) { valkyrie_create(:file_metadata, :original_file, :with_file, file: uploaded_file) }
  let(:file_set) do
    if wings_disabled
      valkyrie_create(:hyrax_file_set,
                      depositor: user.user_key,
                      read_users: [user],
                      files: [file_metadata],
                      original_file: file_metadata)

    # NOTE: It is necessary to switch to an ActiveFedora object below because the test on
    #   L#35 produces the following image conversion error:
    #     Riiif::ConversionError:
    #     Unable to execute command "convert -resize 300 -quality 85 -sampling-factor 4:2:0 -strip
    #       tmp/network_files/f9c086c8ab9d22475371af0974ccf6c3 jpg:-"
    #     convert: no decode delegate for this image format `' @ error/constitute.c/ReadImage/746.
    #     convert: no images defined `jpg:-' @ error/convert.c/ConvertImageCommand/3354.
    else
      create(:file_set, user: user)
    end
  end
  let(:file) { wings_disabled ? file_set : file_set.original_file }
  let(:size) { '300,' }

  before do
    if wings_disabled
      file_set
    else
      Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/world.png'), :original_file)
    end
  end

  describe 'GET /images/:id' do
    context "when the user is authorized" do
      it "returns an image" do
        login_as user

        get Riiif::Engine.routes.url_helpers.image_path(file.id, size: size, format: 'jpg', channels: nil)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq 'image/jpeg'
      end
    end

    context "when the user is not authorized" do
      it "returns an image" do
        get Riiif::Engine.routes.url_helpers.image_path(file.id, size: size, format: 'jpg', channels: nil)
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/jpeg'
      end
    end
  end
end
