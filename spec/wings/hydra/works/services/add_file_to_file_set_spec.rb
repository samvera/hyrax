# frozen_string_literal: true
require 'wings_helper'
require 'wings/hydra/works/services/add_file_to_file_set'

RSpec.describe Wings::Works::AddFileToFileSet, :clean_repo do
  let(:af_file_set)             { create(:file_set, id: 'fileset_id') }
  let!(:file_set)               { af_file_set.valkyrie_resource }

  let(:original_file_use)  { Valkyrie::Vocab::PCDMUse.OriginalFile }
  let(:extracted_text_use) { Valkyrie::Vocab::PCDMUse.ExtractedText }
  let(:thumbnail_use)      { Valkyrie::Vocab::PCDMUse.Thumbnail }

  let(:pdf_filename)  { 'sample-file.pdf' }
  let(:pdf_mimetype)  { 'application/pdf' }
  let(:pdf_file)      { File.open(File.join(fixture_path, pdf_filename)) }

  let(:text_filename) { 'updated-file.txt' }
  let(:text_mimetype) { 'text/plain' }
  let(:text_file)     { File.open(File.join(fixture_path, text_filename)) }

  let(:image_filename) { 'world.png' }
  let(:image_mimetype) { 'image/png' }
  let(:image_file)     { File.open(File.join(fixture_path, image_filename)) }

  let(:update_existing) { true }

  context 'when :use is the name of an association type' do
    context 'and requesting original file' do
      subject { described_class.call(file_set: file_set, file: pdf_file, type: original_file_use) }
      it "builds and uses the association's target" do
        ids = subject.original_file_ids
        expect(ids.size).to eq 1
        expect(ids.first).to be_a Valkyrie::ID
        expect(ids.first.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.query_service.custom_queries.find_file_metadata_by(id: ids.first)
        expect(file_metadata.content.first).to start_with('%PDF-1.3')
        expect(file_metadata.mime_type.first).to eq pdf_mimetype
      end
    end

    context 'and requesting extracted text' do
      subject { described_class.call(file_set: file_set, file: text_file, type: [extracted_text_use]) }
      it "builds and uses the association's target" do
        pending 'fix failing spec'
        # TODO: LDP fails to write the file to Fedora even though the LDP put request looks correct and
        #       has the correct file with expected content as part of the put request.
        ids = subject.extracted_text_ids
        expect(ids.size).to eq 1
        expect(ids.first).to be_a Valkyrie::ID
        expect(ids.first.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.query_service.custom_queries.find_file_metadata_by(id: ids.first)
        expect(file_metadata.content.first).to start_with('some updated content')
        expect(file_metadata.mime_type.first).to eq text_mimetype
      end
    end

    context 'and requesting thumbnail' do
      subject { described_class.call(file_set: file_set, file: image_file, type: thumbnail_use) }
      it "builds and uses the association's target" do
        ids = subject.thumbnail_ids
        expect(ids.size).to eq 1
        expect(ids.first).to be_a Valkyrie::ID
        expect(ids.first.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.query_service.custom_queries.find_file_metadata_by(id: ids.first)
        expect(file_metadata.content.first.present?).to eq true
        expect(file_metadata.mime_type.first).to eq image_mimetype
      end
    end
  end

  context 'when :use is NOT the name of an association type' do
    let(:transcript_use)   { Valkyrie::Vocab::PCDMUse.Transcript }
    let(:service_file_use) { Valkyrie::Vocab::PCDMUse.ServiceFile }

    subject { described_class.call(file_set: file_set, file: text_file, type: transcript_use) }
    before do
      described_class.call(file_set: file_set, file: pdf_file, type: service_file_use)
    end
    it 'adds the given file and applies the specified RDF::URI use to it' do
      pending 'fix failing spec'
      # TODO: Valkyrie resource needs to support filter_files_by_type
      expect(subject.filter_files_by_type(transcript_use).first.content).to start_with('some updated content')
      expect(subject.filter_files_by_type(service_file_use).first.content).to start_with('%PDF-1.3')
    end
  end

  context 'when :versioning => true' do
    let(:versioning) { true }
    subject { described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning) }
    it 'updates the file and creates a version' do
      expect(subject.original_file.versions.all.count).to eq(1)
      expect(subject.original_file.content).to start_with('%PDF-1.3')
    end

    context 'and there are already versions' do
      before do
        described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning)
      end
      subject { described_class.call(file_set: file_set, file: text_file, type: original_file_use, versioning: versioning) }
      it 'adds to the version history' do
        pending 'Valkyrization of versioning for files'
        expect(subject.original_file.versions.all.count).to eq(2)
        expect(subject.original_file.content).to eq("some updated content\n")
      end
    end
  end

  context 'when :versioning => false' do
    let(:versioning) { false }
    before do
      described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning)
    end
    subject { described_class.call(file_set: file_set, file: text_file, type: original_file_use, versioning: versioning) }
    it 'skips creating versions' do
      expect(subject.original_file.versions.all.count).to eq(0)
      expect(subject.original_file.content).to eq("some updated content\n")
    end
  end
end
