# frozen_string_literal: true

# rubocop:disable RSpec/AnyInstance
RSpec.describe Hyrax::Characterization::ValkyrieCharacterizationService do
  describe "run" do
    let(:characterizer) { double(characterize: fits_response) }
    let(:file_set)      { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }
    let(:metadata)      { Hyrax.custom_queries.find_file_metadata_by(id: file.id) }
    let(:upload)        { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }

    let(:file) do
      Hyrax.storage_adapter.upload(resource: file_set,
                                   file: upload,
                                   original_filename: 'test_world.png')
    end

    it 'successfully sets the property values' do
      described_class.run(metadata, file, characterizer: characterizer)

      expect(metadata)
        .to have_attributes(compression: contain_exactly("Deflate/Inflate"),
                            format_label: contain_exactly("Portable Network Graphics"),
                            height: contain_exactly("50"),
                            width: contain_exactly("50"))
    end
  end
end
# rubocop:enable RSpec/AnyInstance
