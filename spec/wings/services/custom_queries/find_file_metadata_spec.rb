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
        expect(subject).to be_a ActiveFedora::File
        expect(subject.id).to eq af_file_id
      end
    end

    context 'when use_valkyrie: true' do
      before { pcdmfile }
      let(:use_valkyrie_value) { true }
      it 'returns ActiveFedora objects' do
        expect(subject).to be_a Hyrax::FileMetadata
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

  describe '.find_many_file_metadata_by_ids' do
    let(:pcdmfile2) do
      Hydra::PCDM::File.new.tap do |f|
        f.id = af_file_id2
        f.content = 'another text file'
        f.original_name = 'more_text.txt'
        f.mime_type = 'text/plain'
        f.save!
      end
    end
    let(:af_file_id2) { 'file2' }
    let(:valk_id2)    { ::Valkyrie::ID.new(af_file_id2) }
    let(:ids)         { [valk_id, valk_id2] }
    let(:use_valkyrie) { true }

    before do
      pcdmfile
      pcdmfile2
    end

    subject { query_service.custom_queries.find_many_file_metadata_by_ids(ids: ids, use_valkyrie: use_valkyrie) }
    context 'when use_valkyrie: false' do
      let(:use_valkyrie) { false }
      it 'returns AF Files' do
        expect(subject).to be_a Array
        expect(subject.size).to eq 2
        expect(subject.first).to be_a ActiveFedora::File
        expect(subject.map { |fm| fm.id.to_s }).to match_array(ids.map(&:to_s))
      end
    end

    context 'when use_valkyrie: true' do
      let(:use_valkyrie) { true }
      it 'returns Hyrax::FileMetadata resources' do
        expect(subject).to be_a Array
        expect(subject.size).to eq 2
        expect(subject.first).to be_a Hyrax::FileMetadata
        expect(subject.map { |fm| fm.id.to_s }).to match_array(ids.map(&:to_s))
      end
    end

    context 'when some ids are for non-file metadata resources' do
      let!(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [valk_id, valk_id2, non_existent_id] }
      it 'only includes file metadata resources' do
        expect(subject).to be_a Array
        expect(subject.size).to eq 2
        expect(subject.first).to be_a Hyrax::FileMetadata
        expect(subject.map { |fm| fm.id.to_s }).to match_array [valk_id.to_s, valk_id2.to_s]
      end
    end

    context 'when not passed any valid ids' do
      let!(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [non_existent_id] }
      it 'returns empty array' do
        expect(subject).to eq []
      end
    end

    context 'when passed empty ids array' do
      let(:ids) { [] }
      it 'returns empty array' do
        expect(subject).to eq []
      end
    end
  end
end
