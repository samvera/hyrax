# frozen_string_literal: true

RSpec.describe ValkyrieCreateDerivativesJob, index_adapter: :solr_index, valkyrie_adapter: :test_adapter, storage_adapter: :test_disk do
  let(:file_metadata) { Hyrax::ValkyrieUpload.file(filename: "image.jpg", file_set: file_set, io: file) }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }
  let(:file) { upload.uploader.file.to_file }
  let(:solr) { Hyrax.index_adapter.connection }
  let(:upload) { FactoryBot.create(:uploaded_file, file_set_uri: file_set.id, file: File.open('spec/fixtures/image.png')) }

  before do
    allow(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_response)
    file_metadata.file_set_id = file_set.id
    Hyrax.persister.save(resource: file_metadata)
  end

  describe "#perform" do
    it "indexes the thumbnail" do
      ValkyrieCreateDerivativesJob.perform_now(file_set.id.to_s, file_metadata.id.to_s)

      solr_doc = solr.get("select", params: { q: "id:#{file_set.id}" })["response"]["docs"].first
      expect(solr_doc["thumbnail_path_ss"]).to include "?file=thumbnail"
    end
  end
end
