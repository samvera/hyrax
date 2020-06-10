# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::FileSets::ByFormat, :clean_repo do
  describe ".query" do
    let(:fs1) { build(:file_set, id: '1234567') }
    let(:fs2) { build(:file_set, id: '2345678') }
    let(:fs3) { build(:file_set, id: '3456789') }
    let(:fs4) { build(:file_set, id: '4567890') }

    before do
      allow(fs1).to receive_messages(mime_type: 'text/plain', format_label: ["plain text"])
      fs1.update_index
      allow(fs2).to receive_messages(mime_type: 'image/jpg', format_label: ["JPEG image"])
      fs2.update_index
      allow(fs3).to receive_messages(mime_type: 'image/tiff', format_label: ["TIFF image"])
      fs3.update_index
      allow(fs4).to receive_messages(mime_type: 'image/jpg', format_label: ["JPEG image"])
      fs4.update_index
    end

    subject { described_class.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: 'jpg (JPEG image)', data: 2 },
                             { label: 'plain (plain text)', data: 1 },
                             { label: 'tiff (TIFF image)', data: 1 }]
      expect(subject.first.label).to eq 'jpg (JPEG image)'
      expect(subject.first.value).to eq 2
    end
  end
end
