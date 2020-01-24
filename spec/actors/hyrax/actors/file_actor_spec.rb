require 'wings/services/file_metadata_builder'
require 'wings/valkyrie/query_service'

RSpec.describe Hyrax::Actors::FileActor do
  include ActionDispatch::TestProcess
  include Hyrax::FactoryHelpers

  let(:user)      { create(:user) }
  let(:file_set)  { create(:file_set) }
  let(:relation)  { :original_file }
  let(:actor)     { described_class.new(file_set, relation, user) }
  let(:fixture)   { fixture_file_upload('/world.png', 'image/png') }
  let(:huf) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, file: fixture) }
  let(:io) { JobIoWrapper.new(file_set_id: file_set.id, user: user, uploaded_file: huf) }
  let(:pcdmfile) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = File.open(fixture.path).read
      f.original_name = fixture.original_filename
      f.save!
    end
  end

  context 'when using active fedora directly' do
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
        expect(CharacterizeJob).to receive(:perform_later).with(FileSetWithExtras, String, huf.uploader.path)
        actor.ingest_file(io)
        expect(file_set.reload.remastered.mime_type).to eq 'image/png'
      end
    end

    it 'uses the provided mime_type' do
      allow(fixture).to receive(:content_type).and_return('image/gif')
      expect(CharacterizeJob).to receive(:perform_later).with(FileSet, String, huf.uploader.path)
      actor.ingest_file(io)
      expect(file_set.reload.original_file.mime_type).to eq 'image/gif'
    end

    context 'with two existing versions from different users' do
      let(:fixture2) { fixture_file_upload('/small_file.txt', 'text/plain') }
      let(:huf2) { Hyrax::UploadedFile.new(user: user2, file_set_uri: file_set.uri, file: fixture2) }
      let(:io2) { JobIoWrapper.new(file_set_id: file_set.id, user: user2, uploaded_file: huf2) }
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
        expect(file_set.original_file.mime_type).to eq 'text/plain'
        expect(file_set.original_file.original_name).to eq 'small_file.txt'
        expect(file_set.original_file.content).to eq fixture2.open.read
        # the user for each version
        expect(Hyrax::VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
        expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user2.user_key]
      end
    end

    describe '#ingest_file' do
      before do
        expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(file_set, io, relation, versioning: false)
      end
      it 'when the file is available' do
        allow(file_set).to receive(:save).and_return(true)
        allow(file_set).to receive(relation).and_return(pcdmfile)
        expect(Hyrax::VersioningService).to receive(:create).with(pcdmfile, user)
        expect(CharacterizeJob).to receive(:perform_later).with(FileSet, pcdmfile.id, huf.uploader.path)
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

  context 'when using valkyrie' do
    let(:user)     { create(:user) }
    let(:file_set) { create(:file_set) }
    let(:relation) { Hyrax::FileSet.original_file_use }
    let(:actor)    { described_class.new(file_set, relation, user, use_valkyrie: true) }
    let(:fixture)  { fixture_file_upload('/world.png', 'image/png') }
    let(:huf) { Hyrax::UploadedFile.new(user: user, file: fixture) }
    let(:io) { JobIoWrapper.new(file_set_id: file_set.id, user: user, uploaded_file: huf, path: huf.uploader.path) }
    let(:storage_adapter) { Hyrax.storage_adapter }
    let(:metadata_adapter) { Hyrax.metadata_adapter }
    let(:persister) { metadata_adapter.persister }
    let(:query_service) { Wings::Valkyrie::QueryService.new(adapter: metadata_adapter) }
    let(:file_metadata) do
      metadata_builder = Wings::FileMetadataBuilder.new(storage_adapter: storage_adapter, persister: persister)
      file_metadata = Hyrax::FileMetadata.for(file: fixture)
      metadata_builder.create(file: fixture, file_metadata: file_metadata, file_set: file_set)
    end

    context 'relation' do
      let(:relation) { RDF::URI.new("http://pcdm.org/use#remastered") }

      it 'uses the relation from the actor' do
        pending 'implementation of Wings::Valkyrie::Persister #save_file_metadata'
        expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user)
        expect(CharacterizeJob).to receive(:perform_later)
        saved_metadata = actor.ingest_file(io)
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.member_by(use: relation).id).to eq saved_metadata.id
      end

      context 'when relation is a string' do
        let(:relation) { 'thumbnail_file' }

        it 'converts relation to URI before using the relation from the actor' do
          pending 'implementation of Wings::Valkyrie::Persister #save_file_metadata'
          expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user)
          expect(CharacterizeJob).to receive(:perform_later)
          saved_metadata = actor.ingest_file(io)
          reloaded = query_service.find_by(id: file_set.id)
          expect(reloaded.member_by(use: relation).id).to eq saved_metadata.id
        end
      end
    end

    xit 'uses the provided mime_type' do
      pending 'implementation of Wings::Valkyrie::Persister #save_file_metadata'
      allow(fixture).to receive(:content_type).and_return('image/gif')
      expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user)
      expect(CharacterizeJob).to receive(:perform_later)
      saved_metadata = actor.ingest_file(io)
      expect(saved_metadata.mime_type).to eq ['image/gif']
    end

    context 'with two existing versions from different users' do
      let(:fixture2) { fixture_file_upload('/small_file.txt', 'text/plain') }
      let(:huf2) { Hyrax::UploadedFile.new(user: user2, file: fixture2) }
      let(:io2) { JobIoWrapper.new(file_set_id: file_set.id, user: user2, uploaded_file: huf2, path: huf2.uploader.path) }
      let(:user2) { create(:user) }
      let(:actor2) { described_class.new(file_set, relation, user2) }
      let(:adapter) { Hyrax.metadata_adapter }
      let(:query_service) { Wings::Valkyrie::QueryService.new(adapter: adapter) }
      let(:versions) do
        reloaded = query_service.find_by(id: file_set.id)
        reloaded.original_file.versions
      end

      before do
        # TODO: WINGS - When #ingest_file works, these should be uncommented.
        # expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user)
        # expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user2)
        # expect(CharacterizeJob).to receive(:perform_later)
        allow(CharacterizeJob).to receive(:perform_later)
        actor.ingest_file(io)
        actor2.ingest_file(io2)
      end

      it 'has two versions' do
        pending 'implementation of Wings::Valkyrie::Persister #save_file_metadata'
        expect(versions.count).to eq 2
        # the current version
        reloaded = query_service.find_by(id: file_set.id)
        expect(Hyrax::VersioningService.latest_version_of(reloaded.original_file).label).to eq ['version2']
        expect(file_set.original_file.mime_type).to eq ['text/plain']
        expect(file_set.original_file.original_filename).to eq ['small_file.txt']
        expect(file_set.original_file.file.read).to eq fixture2.open.read
        # the user for each versioe
        expect(Hyrax::VersionCommitter.where(version_id: versions.first.id.to_s).pluck(:committer_login)).to eq [user.user_key]
        expect(Hyrax::VersionCommitter.where(version_id: versions.last.id.to_s).pluck(:committer_login)).to eq [user2.user_key]
      end
    end

    describe '#ingest_file' do
      it 'when the file is available' do
        pending 'implementation of Wings::Valkyrie::Persister #save_file_metadata'
        expect(Hyrax::VersioningService).to receive(:create).with(Hyrax::FileMetadata, user)
        expect(CharacterizeJob).to receive(:perform_later)
        actor.ingest_file(io)
        reloaded = query_service.find_by(id: file_set.id)
        expect(reloaded.member_by(use: relation)).not_to be_nil
      end
      # rubocop:disable RSpec/AnyInstance
      it 'returns false when save fails' do
        expect(Hyrax::VersioningService).not_to receive(:create).with(Hyrax::FileMetadata, user)
        expect(CharacterizeJob).not_to receive(:perform_later)
        allow_any_instance_of(Wings::FileMetadataBuilder).to receive(:create).and_raise(StandardError)
        expect(actor.ingest_file(io)).to be_falsey
      end
      # rubocop:enable RSpec/AnyInstance
    end
  end
end
