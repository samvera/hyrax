RSpec.describe Hyrax::VersioningService do
  describe '#latest_version_of' do
    let(:user) { build(:user) }
    let(:file) { create(:file_set) }

    before do
      # Add the original_file (this service  creates a version after saving when you call it with versioning: true)
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file, versioning: true)
    end

    describe 'latest_version_of' do
      subject { described_class.latest_version_of(file.original_file).label }

      context 'with one version' do
        it { is_expected.to eq 'version1' }
      end

      context 'with two versions' do
        before do
          file.original_file.create_version
        end
        it { is_expected.to eq 'version2' }
      end
    end
  end
end
