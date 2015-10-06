require 'spec_helper'

describe CurationConcerns::CharacterizationService do
  let(:file_set) { create(:file_set) }

  describe '#run' do
    let(:service_instance) { double }
    let(:file_name) { double }
    it 'creates an instance of the service and calls .characterize on it' do
      expect(described_class).to receive(:new).with(file_set, file_name).and_return(service_instance)
      expect(service_instance).to receive(:characterize)
      described_class.run(file_set, file_name)
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

    let(:file_name) { fixture_file_path('charter.docx') }
    subject { described_class.new(file_set, file_name) }

    it 'characterizes and stores the results' do
      expect(Hydra::FileCharacterization).to receive(:characterize).and_return(fits_xml)

      subject.characterize
      expect(file_set.mime_type).to eq 'application/vnd.oasis.opendocument.text'
      expect(file_set.filename).to eq 'charter.docx'
    end
  end
end
