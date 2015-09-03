require 'spec_helper'

describe CurationConcerns::CharacterizationService do
  let(:generic_file) { create(:generic_file) }

  describe '#run' do
    let(:service_instance) { double }
    it 'creates an instance of the service and calls .characterize on it' do
      expect(described_class).to receive(:new).with(generic_file).and_return(service_instance)
      expect(service_instance).to receive(:characterize)
      described_class.run(generic_file)
    end
  end

  describe 'characterize' do
    let(:fits_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
<fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" version="0.6.2">
  <identification status="CONFLICT">
    <identity format="OpenDocument Text" mimetype="application/vnd.oasis.opendocument.text" toolname="FITS" toolversion="0.6.2">
      <tool toolname="NLNZ Metadata Extractor" toolversion="3.4GA" />
    </identity>
    <identity format="DOCX" mimetype="application/vnd.openxmlformats-officedocument.wordprocessingml.document" toolname="FITS" toolversion="0.6.2">
      <tool toolname="Exiftool" toolversion="9.06" />
    </identity>
  </identification>
  <fileinfo />
  <filestatus />
  <metadata>
    <document />
  </metadata>
</fits>'
    }
    subject { described_class.new(generic_file) }
    before do
      Hydra::Works::UploadFileToGenericFile.call(generic_file, File.open(fixture_file_path('charter.docx')))
    end

    it 'characterizes, extracts fulltext and stores the results' do
      expect(Hydra::Works::FullTextExtractionService).to receive(:run).with(generic_file).and_return('The fulltext')
      expect(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_xml)

      subject.characterize
      expect(generic_file.mime_type).to eq 'application/vnd.oasis.opendocument.text'
      expect(generic_file.filename).to eq 'charter.docx'
      expect(generic_file.extracted_text.content).to eq 'The fulltext'
    end
  end
end
