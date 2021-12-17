# frozen_string_literal: true

# rubocop:disable RSpec/AnyInstance
RSpec.describe Hyrax::Characterization::ValkyrieCharacterizationService do
  describe "run" do
    let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }
    let(:upload)        { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }

    let(:metadata) do
      Hyrax::FileMetadata.for(file: upload).new(id: 'test_id')
    end

    before do
      allow_any_instance_of(described_class).to receive(:extract_metadata).and_return(fits_response)
      described_class.run(metadata, metadata.file)
    end

    it 'successfully sets the property values' do
      expect(metadata.compression).to eq(["Deflate/Inflate"])
      expect(metadata.format_label).to eq(["Portable Network Graphics"])
      expect(metadata.height).to eq(["50"])
      expect(metadata.width).to eq(["50"])
    end
  end
end
# rubocop:enable RSpec/AnyInstance
