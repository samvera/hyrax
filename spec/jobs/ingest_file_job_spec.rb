require 'spec_helper'

describe IngestFileJob do
  let(:generic_file) { create(:generic_file) }
  let(:filename) { fixture_file_path('/world.png') }

  it 'uses the provided mime_type' do
    described_class.perform_now(generic_file.id, filename, 'image/png', 'bob')
    expect(generic_file.reload.original_file.mime_type).to eq 'image/png'
  end

  context 'with two existing versions from different users' do
    let(:file1)       { fixture_file_path 'world.png' }
    let(:file2)       { fixture_file_path 'small_file.txt' }
    let(:actor1)      { described_class.new(generic_file, user) }
    let(:actor2)      { described_class.new(generic_file, second_user) }

    let(:second_user) { create(:user) }
    let(:versions) { generic_file.reload.original_file.versions }

    before do
      described_class.perform_now(generic_file.id, file1, 'image/png', 'bob')
      described_class.perform_now(generic_file.id, file2, 'text/plain', 'bess')
    end

    it 'has two versions' do
      expect(versions.all.count).to eq 2

      # the current version
      expect(CurationConcerns::VersioningService.latest_version_of(generic_file.reload.original_file).label).to eq 'version2'
      expect(generic_file.original_file.content).to eq File.open(file2).read
      expect(generic_file.original_file.mime_type).to eq 'text/plain'
      expect(generic_file.original_file.original_name).to eq 'small_file.txt'

      # the user for each version
      expect(VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq ['bob']
      expect(VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq ['bess']
    end
  end
end
