require 'spec_helper'

describe Sufia::CharacterizationService do
  let(:generic_file) do
    GenericFile.create do |gf|
      gf.apply_depositor_metadata('jcoyne@example.com')
      gf.add_file(File.open(fixture_path + '/charter.docx'), path: 'content', original_name: 'charter.docx')
    end
  end

  describe "#run" do
    it "should characterize and save" do
      expect(generic_file).to receive(:save)
      described_class.run(generic_file)
      expect(generic_file.mime_type).to eq 'application/vnd.oasis.opendocument.text'
    end
  end
end
