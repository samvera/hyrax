require 'redlock'

RSpec.describe Hyrax::Actors::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user)          { create(:user) }
  let(:file_path)     { File.join(fixture_path, 'world.png') }
  let(:file)          { fixture_file_upload(file_path, 'image/png') } # we will override for the different types of File objects
  let(:local_file)    { File.open(file_path) }
  let(:file_set)      { create(:file_set, content: local_file) }
  let(:actor)         { described_class.new(file_set, user) }
  let(:relation)      { :original_file }
  let(:file_actor)    { Hyrax::Actors::FileActor.new(file_set, relation, user) }

  describe 'private' do
    let(:file_set) { build(:file_set) } # avoid 130+ LDP requests

    describe '#assign_visibility?' do
      let(:viz) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

      it 'without params, returns false' do
        expect(actor.send(:assign_visibility?)).to eq false
      end
      it 'with string-keyed or symbol-keyed visibility, returns true' do
        expect(actor.send(:assign_visibility?, visibility: viz)).to eq true
        expect(actor.send(:assign_visibility?, 'visibility' => viz)).to eq true
      end
    end
  end

  describe 'creating metadata, content and attaching to a work' do
    let(:work) { create(:generic_work) }
    let(:date_today) { DateTime.current }

    subject { file_set.reload }

    before do
      allow(DateTime).to receive(:current).and_return(date_today)
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata
      actor.create_content(file)
      actor.attach_to_work(work)
    end

    context 'when a work is provided' do
      it 'adds the FileSet to the parent work' do
        expect(subject.parents).to eq [work]
        expect(work.reload.file_sets).to include(subject)

        # Confirming that date_uploaded and date_modified were set
        expect(subject.date_uploaded).to eq date_today.utc
        expect(subject.date_modified).to eq date_today.utc
        expect(subject.depositor).to eq user.email

        # Confirm that embargo/lease are not set.
        expect(subject).not_to be_under_embargo
        expect(subject).not_to be_active_lease
        expect(subject.visibility).to eq 'restricted'
      end
    end
  end

  describe '#create_content' do
    before do
      expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).with(any_args).and_return(JobIoWrapper.new)
      expect(IngestJob).to receive(:perform_later).with(JobIoWrapper)
    end

    it 'calls ingest_file' do
      actor.create_content(file)
    end

    context 'when an alternative relationship is specified' do
      let(:relation) { :remastered }

      it 'calls ingest_file' do
        actor.create_content(file, :remastered)
      end
    end

    context 'using ::File' do
      let(:file) { local_file }

      before { actor.create_content(local_file) }

      it 'sets the label and title' do
        expect(file_set.label).to eq(File.basename(local_file))
        expect(file_set.title).to eq([File.basename(local_file)])
      end

      it 'gets the mime_type from original_file' do
        expect(file_set.mime_type).to eq('image/png')
      end
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:long_name) do
        'an absurdly long title that goes on way to long and messes up the display of the page which should not need ' \
          'to be this big in order to show this impossibly long, long, long, oh so long string'
      end
      let(:short_name) { 'Nice Short Name' }

      before do
        allow(file_set).to receive(:label).and_return(short_name)
        actor.create_content(file)
      end

      subject { file_set.title }

      it { is_expected.to match_array [short_name] }
    end

    context 'when a label is already specified' do
      let(:label) { 'test_file.png' }
      let(:file_set) do
        FileSet.new do |f|
          f.apply_depositor_metadata(user.user_key)
          f.label = label
        end
      end
      let(:actor) { described_class.new(file_set, user) }

      before do
        actor.create_content(file)
      end

      it "retains the object's original label" do
        expect(file_set.label).to eql(label)
      end
    end
  end

  describe '#create_content when from_url is true' do
    before do
      expect(JobIoWrapper).to receive(:create_with_varied_file_handling!).with(any_args).once.and_call_original
    end

    it 'calls ingest_file and kicks off jobs' do
      actor.create_content(file, from_url: true)
      expect(VisibilityCopyJob).to have_been_enqueued
      expect(InheritPermissionsJob).to have_been_enqueued
    end

    context 'when an alternative relationship is specified' do
      before do
        # Relationship must be declared before being used. Inject it here.
        FileSet.class_eval do
          directly_contains_one :remastered, through: :files, type: ::RDF::URI("http://otherpcdm.example.org/use#Remastered"), class_name: 'Hydra::PCDM::File'
        end
      end

      it 'calls ingest_file' do
        actor.create_content(file, :remastered, from_url: true)
      end
    end

    context 'using ::File' do
      let(:file) { local_file }

      before { actor.create_content(local_file, from_url: true) }

      it 'sets the label and title' do
        expect(file_set.label).to eq(File.basename(local_file))
        expect(file_set.title).to eq([File.basename(local_file)])
      end

      it 'gets the mime_type from original_file' do
        expect(file_set.mime_type).to eq('image/png')
      end
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:long_name) do
        'an absurdly long title that goes on way to long and messes up the display of the page which should not need ' \
        'to be this big in order to show this impossibly long, long, long, oh so long string'
      end
      let(:short_name) { 'Nice Short Name' }

      before do
        allow(file_set).to receive(:label).and_return(short_name)
        actor.create_content(file, from_url: true)
      end

      subject { file_set.title }

      it { is_expected.to match_array [short_name] }
    end

    context 'when a label is already specified' do
      let(:label) { 'test_file.png' }
      let(:file_set) do
        FileSet.new do |f|
          f.apply_depositor_metadata(user.user_key)
          f.label = label
        end
      end
      let(:actor) { described_class.new(file_set, user) }

      before do
        actor.create_content(file, from_url: true)
      end

      it "retains the object's original label" do
        expect(file_set.label).to eql(label)
      end
    end
  end

  describe "#update_metadata" do
    it "is successful" do
      expect(actor.update_metadata("title" => ["updated title"])).to be true
      expect(file_set.reload.title).to eq ["updated title"]
    end
  end

  describe "#update_content" do
    it 'calls ingest_file and returns queued job' do
      expect(IngestJob).to receive(:perform_later).with(any_args).and_return(IngestJob.new)
      expect(actor.update_content(local_file)).to be_a(IngestJob)
    end
    it 'runs callbacks', perform_enqueued: [IngestJob] do
      # Do not bother ingesting the file -- test only the result of callback
      allow(file_actor).to receive(:ingest_file).with(any_args).and_return(double)
      expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
      actor.update_content(local_file)
    end
  end

  describe "#destroy" do
    it "destroys the object" do
      actor.destroy
      expect { file_set.reload }.to raise_error Ldp::Gone
    end

    context "representative, renderings and thumbnail of a work" do
      let!(:work) do
        work = create(:generic_work)
        # this is not part of a block on the create, since the work must be saved
        # before the representative can be assigned
        work.ordered_members << file_set
        work.representative = file_set
        work.thumbnail = file_set
        work.renderings = [file_set]
        work.save
        work
      end

      it "removes representative, renderings, thumbnail, and the proxy association" do
        gw = GenericWork.find(work.id)
        expect(gw.representative_id).to eq(file_set.id)
        expect(gw.thumbnail_id).to eq(file_set.id)
        expect { actor.destroy }.to change { ActiveFedora::Aggregation::Proxy.count }.by(-1)
        gw.reload
        expect(gw.representative_id).to be_nil
        expect(gw.thumbnail_id).to be_nil
        expect(gw.rendering_ids).to eq([])
      end
    end
  end

  describe "#attach_to_work" do
    let(:work) { build(:public_generic_work) }

    before do
      allow(actor).to receive(:acquire_lock_for).and_yield
    end

    it 'copies file_set visibility from the parent' do
      actor.attach_to_work(work)
      expect(file_set.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    context 'without representative and thumbnail' do
      it 'assigns them (with persistence)' do
        actor.attach_to_work(work)
        expect(work.representative).to eq(file_set)
        expect(work.thumbnail).to eq(file_set)
        expect { work.reload }.not_to change { [work.representative.id, work.thumbnail.id] }
      end
    end

    context 'with representative and thumbnail' do
      it 'does not (re)assign them' do
        allow(work).to receive(:thumbnail_id).and_return('ab123c78h')
        allow(work).to receive(:representative_id).and_return('zz365c78h')
        expect(work).not_to receive(:representative=)
        expect(work).not_to receive(:thumbnail=)
        actor.attach_to_work(work)
      end
    end

    context 'with multiple versions' do
      let(:work_v1) { create(:generic_work) } # this version of the work has no members
      let(:coll) { create(:collection, title: ['Cats on Roombas']) }

      before do # another version of the same work is saved with a member
        work_v2 = ActiveFedora::Base.find(work_v1.id)
        work_v2.ordered_members << create(:file_set)
        work_v2.description = ["3 kittens"]
        work_v2.member_of_collections = [coll]
        work_v2.save!
      end

      it "writes to the most up to date version" do
        actor.attach_to_work(work_v1)
        expect(work_v1.ordered_members.ids.size).to eq 2
        expect(work_v1.member_of_collections).to eq([coll])
        expect(work_v1.description).to eq(["3 kittens"])
      end
    end
  end

  describe "#file_actor_class" do
    subject { actor.file_actor_class }

    it { is_expected.to eq(Hyrax::Actors::FileActor) }

    context "overridden" do
      let(:custom_fs_actor_class) do
        class ::CustomFileActor < Hyrax::Actors::FileActor
        end
        Class.new(described_class) do
          def file_actor_class
            CustomFileActor
          end
        end
      end
      let(:actor) { custom_fs_actor_class.new(file_set, user) }

      after { Object.send(:remove_const, :CustomFileActor) }
      it { is_expected.to eq(CustomFileActor) }
    end
  end

  describe '#revert_content', perform_enqueued: [IngestJob] do
    let(:file_set) { create(:file_set, user: user) }
    let(:file1)    { "small_file.txt" }
    let(:version1) { "version1" }
    let(:restored_content) { file_set.reload.original_file }

    before do
      actor.create_content(fixture_file_upload(file1))
      actor.create_content(fixture_file_upload('hyrax_generic_stub.txt'))
      actor.file_set.reload
    end

    it "restores the first versions's content and metadata" do
      actor.revert_content(version1)
      expect(restored_content.original_name).to eq file1
    end
  end
end
