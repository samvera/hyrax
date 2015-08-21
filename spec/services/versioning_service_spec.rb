require 'spec_helper'

describe CurationConcerns::VersioningService do
  describe '#latest_version_of' do
    let(:file) do
      GenericFile.create do |f|
        f.apply_depositor_metadata('mjg36')
      end
    end

    before do
      # Add the original_file (this service  creates a version after saving when you call it with versioning: true)
      Hydra::Works::AddFileToGenericFile.call(file, File.open(fixture_file_path('world.png')), :original_file, versioning: true)
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
