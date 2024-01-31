# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Characterization::ValkyrieCharacterizationService do
  describe "run" do
    let(:characterizer) { double(characterize: fits_response) }
    let(:fits_response) { IO.read('spec/fixtures/png_fits.xml') }
    let(:listener)      { Hyrax::Specs::SpyListener.new }

    let(:file_set)      { FactoryBot.valkyrie_create(:hyrax_file_set, files: [file_metadata], original_file: file_metadata) }
    let(:file_metadata) { valkyrie_create(:file_metadata, :original_file, :with_file, file: file, mime_type: 'image/png') }
    let(:file)          { create(:uploaded_file, file: File.open('spec/fixtures/world.png')) }

    before do
      Hyrax.publisher.subscribe(listener)
      described_class
        .run(metadata: file_metadata, file: file_set.original_file.file, characterizer: characterizer)
    end
    after { Hyrax.publisher.unsubscribe(listener) }

    describe '#run' do
      it 'successfully sets the property values' do
        expect(file_metadata)
          .to have_attributes(compression: contain_exactly("Deflate/Inflate"),
                              format_label: contain_exactly("Portable Network Graphics"),
                              height: contain_exactly("50"),
                              width: contain_exactly("50"))
      end

      it 'publishes metadata updated for file metadata node' do
        expect(listener.file_metadata_updated&.payload&.values&.map(&:id))
          .to include(::User.system_user.id, file_metadata.id)
      end
    end
  end
end
