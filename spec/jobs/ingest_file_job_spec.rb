require 'spec_helper'

describe IngestFileJob do
  let(:file_set) { create(:file_set) }
  let(:filename) { fixture_path + '/world.png' }
  let(:user)     { create(:user) }

  context 'when given a relationship' do
    before do
      class FileSetWithExtras < FileSet
        directly_contains_one :remastered, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
      end
    end
    let(:file_set) do
      FileSetWithExtras.create!(attributes_for(:file_set)) do |file|
        file.apply_depositor_metadata(user.user_key)
      end
    end
    after do
      Object.send(:remove_const, :FileSetWithExtras)
    end
    it 'uses the provided relationship' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, filename)
      described_class.perform_now(file_set, filename, user, mime_type: 'image/png', relation: 'remastered')
      expect(file_set.reload.remastered.mime_type).to eq 'image/png'
    end
  end

  context 'when given a mime_type' do
    it 'uses the provided mime_type' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, filename)
      described_class.perform_now(file_set, filename, user, mime_type: 'image/png')
      expect(file_set.reload.original_file.mime_type).to eq 'image/png'
    end
  end

  context 'when not given a mime_type' do
    before { allow(Hyrax::VersioningService).to receive(:create) }
    it 'passes a decorated instance of the file with a nil mime_type' do
      # The parameter versioning: false instructs the machinery in Hydra::Works NOT to do versioning
      # so it can be handled later on.
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(
        file_set,
        instance_of(Hydra::Derivatives::IoDecorator),
        :original_file,
        versioning: false
      ).and_call_original
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, filename)
      described_class.perform_now(file_set, filename, user)
    end
  end

  context 'with two existing versions from different users' do
    let(:file1)    { fixture_path + '/world.png' }
    let(:file2)    { fixture_path + '/small_file.txt' }
    let(:versions) { file_set.reload.original_file.versions }
    let(:user2) { create(:user) }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(any_args)
      described_class.perform_now(file_set, file1, user.user_key, mime_type: 'image/png')
      described_class.perform_now(file_set, file2, user2.user_key, mime_type: 'text/plain')
    end

    it 'has two versions' do
      expect(versions.all.count).to eq 2

      # the current version
      expect(Hyrax::VersioningService.latest_version_of(file_set.reload.original_file).label).to eq 'version2'
      expect(file_set.original_file.content).to eq File.open(file2).read
      expect(file_set.original_file.mime_type).to eq 'text/plain'
      expect(file_set.original_file.original_name).to eq 'small_file.txt'

      # the user for each version
      expect(Hyrax::VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
      expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user2.user_key]
    end
  end
end
