# frozen_string_literal: true

RSpec.describe Hyrax::Characterization::FileSetDescription, valkyrie_adapter: :test_adapter do
  subject(:description) { described_class.new(file_set: file_set) }

  let(:ctype) { 'image/png' }
  let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', ctype) }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, file_ids: file_ids) }
  let(:file_ids) { [] }

  describe '#mime_type' do
    context 'before the file set is saved' do
      let(:file_set) { FactoryBot.build(:hyrax_file_set) }

      it 'has a generic MIME type' do
        expect(description.mime_type).to eq 'application/octet-stream'
      end
    end

    context 'when it has no files' do
      it 'has a generic MIME type' do
        expect(description.mime_type).to eq 'application/octet-stream'
      end
    end

    context 'when it has an original file' do
      let(:file_ids) { [original_file.id] }
      let(:original_file) { Hyrax.persister.save(resource: Hyrax::FileMetadata.for(file: file)) }

      it { is_expected.to be_image }

      it 'has a mime type from a file' do
        expect(description.mime_type).to eq ctype
      end
    end
  end
end
