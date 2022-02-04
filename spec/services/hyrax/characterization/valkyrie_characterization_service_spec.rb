# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/specs/spy_listener'

# rubocop:disable RSpec/AnyInstance
RSpec.describe Hyrax::Characterization::ValkyrieCharacterizationService do
  describe "run" do
    let(:characterizer) { double(characterize: fits_response) }
    let(:file_set)      { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }
    let(:listener)      { Hyrax::Specs::SpyListener.new }
    let(:metadata)      { Hyrax.custom_queries.find_file_metadata_by(id: file.id) }
    let(:upload)        { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }

    let(:file) do
      Hyrax.storage_adapter.upload(resource: file_set,
                                   file: upload,
                                   original_filename: 'test_world.png')
    end

    before { Hyrax.publisher.subscribe(listener) }
    after { Hyrax.publisher.unsubscribe(listener) }

    describe '#run' do
      it 'successfully sets the property values' do
        described_class
          .run(metadata: metadata, file: file, characterizer: characterizer)

        expect(metadata)
          .to have_attributes(compression: contain_exactly("Deflate/Inflate"),
                              format_label: contain_exactly("Portable Network Graphics"),
                              height: contain_exactly("50"),
                              width: contain_exactly("50"))
      end

      it 'publishes metadata updated for file metadata node' do
        described_class
          .run(metadata: metadata, file: file, characterizer: characterizer)

        expect(listener.file_metadata_updated&.payload)
          .to include(user: ::User.system_user,
                      metadata: metadata)
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
