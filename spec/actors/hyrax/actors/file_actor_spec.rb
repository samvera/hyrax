RSpec.describe Hyrax::Actors::FileActor do
  include ActionDispatch::TestProcess
  include Hyrax::FactoryHelpers

  let(:user)     { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:relation) { :original_file }
  let(:actor)    { described_class.new(file_set, relation, user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }
  let(:io) { Hydra::Derivatives::IoDecorator.new(uploaded_file, uploaded_file.content_type, uploaded_file.original_filename) }
  let(:pcdmfile) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = File.open(uploaded_file.path).read
      f.original_name = uploaded_file.original_filename
      f.save!
    end
  end

  context 'relation' do
    let(:relation) { :remastered }
    let(:file_set) do
      FileSetWithExtras.create!(attributes_for(:file_set)) do |file|
        file.apply_depositor_metadata(user.user_key)
      end
    end

    before do
      class FileSetWithExtras < FileSet
        directly_contains_one :remastered, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
      end
    end
    after do
      Object.send(:remove_const, :FileSetWithExtras)
    end
    it 'uses the relation from the actor' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, io.tempfile.path)
      actor.ingest_file(io)
      expect(file_set.reload.remastered.mime_type).to eq 'image/png'
    end
  end

  context 'when given a mime_type' do
    let(:uploaded_file) { fixture_file_upload('/world.png', 'image/gif') }

    it 'uses the provided mime_type' do
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, io.tempfile.path)
      actor.ingest_file(io)
      expect(file_set.reload.original_file.mime_type).to eq 'image/gif'
    end
  end

  context 'when not given a mime_type' do
    before { allow(Hyrax::VersioningService).to receive(:create) }
    it 'passes a decorated instance of the file with a nil mime_type' do
      # The parameter versioning: false instructs the machinery in Hydra::Works to defer versioning
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(
        file_set,
        io,
        relation,
        versioning: false
      ).and_call_original
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String, io.tempfile.path)
      actor.ingest_file(io)
    end
  end

  context 'with two existing versions from different users' do
    let(:uploaded_file2) { fixture_file_upload('/small_file.txt', 'text/plain') }
    let(:io2) { Hydra::Derivatives::IoDecorator.new(uploaded_file2, uploaded_file2.content_type, uploaded_file2.original_filename) }
    let(:user2) { create(:user) }
    let(:actor2) { described_class.new(file_set, relation, user2) }
    let(:versions) { file_set.reload.original_file.versions }

    before do
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(any_args)
      actor.ingest_file(io)
      actor2.ingest_file(io2)
    end

    it 'has two versions' do
      expect(versions.all.count).to eq 2
      # the current version
      expect(Hyrax::VersioningService.latest_version_of(file_set.reload.original_file).label).to eq 'version2'
      expect(file_set.original_file.content).to eq uploaded_file2.open.read
      expect(file_set.original_file.mime_type).to eq 'text/plain'
      expect(file_set.original_file.original_name).to eq 'small_file.txt'
      # the user for each version
      expect(Hyrax::VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
      expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user2.user_key]
    end
  end

  describe '#ingest_file' do
    before do
      expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(file_set, io, relation, versioning: false)
      expect(Hyrax::WorkingDirectory).not_to receive(:copy_file_to_working_directory)
    end
    it 'when the file is available' do
      allow(file_set).to receive(:save).and_return(true)
      allow(file_set).to receive(:original_file).and_return(pcdmfile)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, pcdmfile.id, io.tempfile.path)
      actor.ingest_file(io)
    end
    it 'returns false when save fails' do
      allow(file_set).to receive(:save).and_return(false)
      expect(actor.ingest_file(io)).to be_falsey
    end
  end

  describe '#revert_to' do
    let(:revision_id) { 'asdf1234' }

    before do
      allow(pcdmfile).to receive(:restore_version).with(revision_id)
      allow(file_set).to receive(relation).and_return(pcdmfile)
      expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, user)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, pcdmfile.id)
    end

    it 'reverts to a previous version of a file' do
      expect(file_set).not_to receive(:remastered)
      expect(actor.relation).to eq(:original_file)
      actor.revert_to(revision_id)
    end

    describe 'for a different relation' do
      let(:relation) { :remastered }

      it 'reverts to a previous version of a file' do
        expect(actor.relation).to eq(:remastered)
        actor.revert_to(revision_id)
      end
      it 'does not rely on the default relation' do
        pending "Hydra::Works::VirusCheck must support other relations: https://github.com/samvera/hyrax/issues/1187"
        expect(actor.relation).to eq(:remastered)
        expect(file_set).not_to receive(:original_file)
        actor.revert_to(revision_id)
      end
    end
  end
end
