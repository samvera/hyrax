# frozen_string_literal: true
RSpec.describe Hyrax::VersioningService do
  let(:user) { build(:user) }
  let(:file) { create(:file_set) }

  describe 'using ActiveFedora', :active_fedora do
    before do
      # Add the original_file (this service creates a version after saving when you call it with versioning: true)
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file, versioning: true)
    end

    describe '#supports_multiple_versions?' do
      subject do
        described_class.new(resource: file.original_file).supports_multiple_versions?
      end

      it { is_expected.to be true }
    end

    describe '#versions' do
      subject do
        described_class.new(resource: file.original_file).versions.map do |v|
          Hyrax.config.translate_uri_to_id.call(v.uri)
        end
      end

      context 'without version data' do
        before do
          allow(file.original_file).to receive(:has_versions?).and_return(false)
        end
        it { is_expected.to eq [] }
      end

      context 'with one version' do
        it { is_expected.to eq ["#{file.original_file.id}/fcr:versions/version1"] }
      end

      context 'with two versions' do
        before do
          file.original_file.create_version
        end
        it {
          is_expected.to eq [
            "#{file.original_file.id}/fcr:versions/version1",
            "#{file.original_file.id}/fcr:versions/version2"
          ]
        }
      end
    end

    describe '.versioned_file_id' do
      subject { described_class.versioned_file_id file.original_file }

      context 'without version data' do
        before do
          allow(file.original_file).to receive(:has_versions?).and_return(false)
        end
        it { is_expected.to eq file.original_file.id }
      end

      context 'with one version' do
        it { is_expected.to eq "#{file.original_file.id}/fcr:versions/version1" }
      end

      context 'with two versions' do
        before do
          file.original_file.create_version
        end
        it { is_expected.to eq "#{file.original_file.id}/fcr:versions/version2" }
      end
    end

    describe '.latest_version_of' do
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

  describe 'using valkyrie' do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)]) }
    let(:file_set) { query_service.find_members(resource: work).first }
    let(:file_metadata) { query_service.custom_queries.find_file_metadata_by(id: file_set.file_ids.first) }
    let(:uploaded) { storage_adapter.find_by(id: file_metadata.file_identifier) }
    let(:query_service) { Hyrax.query_service }
    let(:storage_adapter) { Hyrax.storage_adapter }

    describe '#supports_multiple_versions?' do
      subject do
        described_class.new(resource: file_metadata).supports_multiple_versions?
      end

      context 'when versions are unsupported' do
        before do
          allow(storage_adapter).to receive(:supports?).and_return(false)
        end

        it { is_expected.to be false }
      end

      context 'when versions are supported' do
        it { is_expected.to be true }
      end
    end

    describe '#versions' do
      subject { described_class.new(resource: file_metadata).versions.map(&:version_id) }

      context 'when versions are unsupported' do
        before do
          allow(storage_adapter).to receive(:supports?).and_return(false)
        end
        it { is_expected.to eq [] }
      end

      context 'without version data' do
        before do
          allow(storage_adapter).to receive(:supports?).and_return(true)
          allow(storage_adapter).to receive(:find_versions).and_return([])
        end
        it { is_expected.to eq [] }
      end

      context 'with one version' do
        it { is_expected.to eq [uploaded.version_id] }
      end

      context 'with two versions' do
        let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
        let(:new_version) { storage_adapter.upload_version(id: uploaded.id, file: another_file) }
        before do
          new_version
        end
        it {
          is_expected.to eq [
            uploaded.version_id,
            new_version.version_id
          ]
        }
      end
    end

    describe '.versioned_file_id' do
      subject { described_class.versioned_file_id file_metadata }

      context 'when versions are unsupported' do
        before do
          allow(storage_adapter).to receive(:supports?).and_return(false)
        end
        it { is_expected.to eq uploaded.id }
      end

      context 'without version data' do
        before do
          allow(storage_adapter).to receive(:supports?).and_return(true)
          allow(storage_adapter).to receive(:find_versions).and_return([])
        end
        it { is_expected.to eq uploaded.id }
      end

      context 'with one version' do
        it { is_expected.to eq uploaded.version_id }
      end

      context 'with two versions' do
        let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
        let(:new_version) { storage_adapter.upload_version(id: uploaded.id, file: another_file) }
        before do
          new_version
        end
        it { is_expected.to eq new_version.version_id }
      end
    end

    describe '.latest_version_of' do
      subject { described_class.latest_version_of(file_metadata).version_id }

      context 'with one version' do
        it { is_expected.to eq uploaded.version_id }
      end

      context 'with two versions' do
        let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
        let(:new_version) { storage_adapter.upload_version(id: uploaded.id, file: another_file) }
        before do
          new_version
        end
        it { is_expected.to eq new_version.version_id }
      end
    end
  end
end
