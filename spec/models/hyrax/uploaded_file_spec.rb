# frozen_string_literal: true
RSpec.describe Hyrax::UploadedFile do
  let(:file1) { File.open(fixture_path + '/world.png') }

  subject { described_class.create(file: file1) }

  it "is not in the public directory" do
    temp_dir = Rails.root + 'tmp'
    expect(subject.file.path).to start_with temp_dir.to_s
  end

  it "scans for viruses" do
    allow(Hyrax::VirusScanner).to receive(:infected?).and_return(true)
    expect(subject.errors[:file]).to include(/Virus detected/)
  end
end
