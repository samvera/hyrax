RSpec.describe Hyrax::Statistics::FileSets::ByFormat, :clean_repo do
  describe ".query" do
    let(:file1) { fixture_file_upload('/small_file.txt', 'text/plain') }
    let(:file2) { fixture_file_upload('/1x1.jpg', 'image/jpg') }
    let(:file3) { fixture_file_upload('/1x1.tif', 'image/tiff') }
    let(:file4) { fixture_file_upload('/1x1.jpg', 'image/jpg') }
    let!(:fs1) { create_for_repository(:file_set, content: file1, format_label: ["plain text"]) }
    let!(:fs2) { create_for_repository(:file_set, content: file2, format_label: ["JPEG image"]) }
    let!(:fs3) { create_for_repository(:file_set, content: file3, format_label: ["TIFF image"]) }
    let!(:fs4) { create_for_repository(:file_set, content: file4, format_label: ["JPEG image"]) }

    subject { described_class.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: 'jpeg (JPEG image)', data: 2 },
                             { label: 'plain; charset=ISO-8859-1 (plain text)', data: 1 },
                             { label: 'tiff (TIFF image)', data: 1 }]
      expect(subject.first.label).to eq 'jpeg (JPEG image)'
      expect(subject.first.value).to eq 2
    end
  end
end
