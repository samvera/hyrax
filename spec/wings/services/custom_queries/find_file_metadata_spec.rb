# frozen_string_literal: true
require 'wings_helper'
require 'wings/services/custom_queries/find_file_metadata'

RSpec.describe Wings::CustomQueries::FindFileMetadata, :clean_repo do
  let(:query_service) { Hyrax.query_service }

  let(:pcdmfile) do
    Hydra::PCDM::File.new.tap do |f|
      f.id = af_file_id
      f.content = 'some text for content'
      f.original_name = 'some_text.txt'
      f.mime_type = 'text/plain'
      f.save!
    end
  end
  let(:af_file_id) { 'file1' }
  let(:valk_id) { ::Valkyrie::ID.new(af_file_id) }

  let(:subject) { query_service.custom_queries.find_file_metadata_by(id: valk_id, use_valkyrie: use_valkyrie_value) }

  describe '.find_file_metadata_by' do
    context 'when use_valkyrie: false' do
      before { pcdmfile }
      let(:use_valkyrie_value) { false }
      it 'returns AF File' do
        expect(subject.is_a?(ActiveFedora::File)).to be true
        expect(subject.id).to eq af_file_id
      end
    end

    context 'when use_valkyrie: true' do
      before { pcdmfile }
      let(:use_valkyrie_value) { true }
      it 'returns ActiveFedora objects' do
        expect(subject.is_a?(Hyrax::FileMetadata)).to be true
        expect(subject.id).to eq valk_id
      end
    end

    context 'when invalid id' do
      let(:use_valkyrie_value) { true }
      let(:valk_id) { ::Valkyrie::ID.new('1212121212') }
      it 'returns error' do
        expect { subject } .to raise_error
      end
    end
  end
end
