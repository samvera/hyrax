RSpec.describe Hyrax::VersioningService do
  include ActionDispatch::TestProcess
  describe '#latest_version_of' do
    let(:user) { build(:user) }
    let(:file) { create(:file_set, content: content) }
    let(:content) { fixture_file_upload('/world.png', 'image/png') }

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
