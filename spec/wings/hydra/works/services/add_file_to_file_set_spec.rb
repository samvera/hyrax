# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/hydra/works/services/add_file_to_file_set'

RSpec.describe Wings::Works::AddFileToFileSet, :active_fedora, :clean_repo do
  let(:af_file_set)             { create(:file_set, id: 'fileset_id') }
  let!(:file_set)               { af_file_set.valkyrie_resource }

  let(:original_file_use)  { Hyrax::FileMetadata::Use::ORIGINAL_FILE }
  let(:extracted_text_use) { Hyrax::FileMetadata::Use::EXTRACTED_TEXT }
  let(:thumbnail_use)      { Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE }

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
        id = subject.original_file_id
        expect(id).to be_a Valkyrie::ID
        expect(id.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: id)
        expect(file_metadata.mime_type).to eq pdf_mimetype
      end
    end

    context 'and requesting extracted text' do
      subject { described_class.call(file_set: file_set, file: text_file, type: [extracted_text_use]) }
      it "builds and uses the association's target" do
        id = subject.extracted_text_id
        expect(id).to be_a Valkyrie::ID
        expect(id.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: id)
        expect(file_metadata.mime_type).to eq text_mimetype
      end
    end

    context 'and requesting thumbnail' do
      subject { described_class.call(file_set: file_set, file: image_file, type: thumbnail_use) }

      it "builds and uses the association's target" do
        id = subject.thumbnail_id
        expect(id).to be_a Valkyrie::ID
        expect(id.to_s).to start_with "#{file_set.id}/files/"

        file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: id)
        expect(file_metadata.mime_type).to eq image_mimetype
      end
    end
  end

  context 'when :use is NOT the name of an association type' do
    let(:transcript_use)   { Valkyrie::Vocab::PCDMUse.Transcript }
    let(:service_file_use) { Valkyrie::Vocab::PCDMUse.ServiceFile }

    let(:updated_file_set) { described_class.call(file_set: file_set, file: pdf_file, type: service_file_use) }
    let(:transcript_file_set) { described_class.call(file_set: updated_file_set, file: text_file, type: transcript_use) }

    it 'adds the given file and applies the specified RDF::URI use to it' do
      ids = transcript_file_set.file_ids
      expect(ids.size).to eq 2
      expect(ids.first).to be_a Valkyrie::ID
      expect(ids.first.to_s).to start_with "#{file_set.id}/files/"
      expect(Hyrax.custom_queries.find_many_file_metadata_by_use(resource: transcript_file_set, use: transcript_use).first.pcdm_use)
        .to include transcript_use
      expect(Hyrax.custom_queries.find_many_file_metadata_by_use(resource: transcript_file_set, use: service_file_use).first.pcdm_use)
        .to include service_file_use
    end
  end

  context 'when :versioning => true' do
    let(:versioning) { true }
    subject { described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning) }
    it 'updates the file and creates a version' do
      pending 'Valkyrization of versioning in Hyrax::FileMetadata'
      expect(subject.original_file.versions.all.count).to eq(1)
      expect(subject.original_file.content).to start_with('%PDF-1.3')
    end

    context 'and there are already versions' do
      subject do
        updated_file_set = described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning)
        described_class.call(file_set: updated_file_set, file: text_file, type: original_file_use, versioning: versioning)
      end
      it 'adds to the version history' do
        pending 'Valkyrization of versioning in Hyrax::FileMetadata'
        expect(subject.original_file.versions.all.count).to eq(2)
        expect(subject.original_file.content).to eq("some updated content\n")
      end
    end
  end

  context 'when :versioning => false' do
    let(:versioning) { false }
    subject do
      updated_file_set = described_class.call(file_set: file_set, file: pdf_file, type: original_file_use, versioning: versioning)
      described_class.call(file_set: updated_file_set, file: text_file, type: original_file_use, versioning: versioning)
    end
    it 'skips creating versions' do
      pending 'Valkyrization of versioning in Hyrax::FileMetadata'
      expect(subject.original_file.versions.all.count).to eq(0)
      expect(subject.original_file.content).to eq("some updated content\n")
    end
  end
end
