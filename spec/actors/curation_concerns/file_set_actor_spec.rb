require 'spec_helper'
require 'redlock'

describe CurationConcerns::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:actor) { described_class.new(file_set, user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }
  let(:local_file) { File.open(File.join(fixture_path, 'world.png')) }

  describe 'creating metadata and content' do
    let(:upload_set_id) { nil }
    let(:work) { nil }
    subject { file_set.reload }
    let(:date_today) { DateTime.now }

    before do
      allow(DateTime).to receive(:now).and_return(date_today)
    end

    before do
      expect(CharacterizeJob).to receive(:perform_later)
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, 'image/png', user, 'original_file')
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata(work)
      actor.create_content(uploaded_file)
    end

    context 'when a work is not provided' do
      it "leaves the association blank" do
        expect(subject.parents).to be_empty
      end
    end

    context 'when a work is provided' do
      let(:work) { create(:generic_work) }

      it 'adds the FileSet to the parent work' do
        expect(subject.parents).to eq [work]
        expect(work.reload.file_sets).to include(subject)

        # Confirming that date_uploaded and date_modified were set
        expect(subject.date_uploaded).to eq date_today.utc
        expect(subject.date_modified).to eq date_today.utc
        expect(subject.depositor).to eq user.email

        # Confirm that embargo/lease are not set.
        expect(subject).to_not be_under_embargo
        expect(subject).to_not be_active_lease
        expect(subject.visibility).to eq 'restricted'
      end
    end
  end

  describe "#create_metadata" do
    let(:work) { create(:public_generic_work) }

    it 'copies visibility from the parent' do
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata(work)
      saved_file = file_set.reload
      expect(saved_file.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  describe '#create_content' do
    it 'calls ingest file job' do
      expect(CharacterizeJob).to receive(:perform_later)
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, 'image/png', user, 'original_file')
      actor.create_content(uploaded_file)
    end

    context 'when an alternative relationship is specified' do
      it 'calls ingest file job' do
        expect(CharacterizeJob).to receive(:perform_later)
        expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png$/, 'image/png', user, 'remastered')
        actor.create_content(uploaded_file, 'remastered')
      end
    end

    context 'using ::File' do
      before do
        allow(CharacterizeJob).to receive(:perform_later)
        allow(IngestFileJob).to receive(:perform_later)
        actor.create_content(local_file)
      end

      it 'sets the label and title' do
        expect(file_set.label).to eq(File.basename(local_file))
        expect(file_set.title).to eq([File.basename(local_file)])
      end

      it 'does not set the mime_type' do
        expect(file_set.mime_type).to be_nil
      end
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:file)       { 'world.png' }
      let(:long_name)  { 'an absurdly long title that goes on way to long and messes up the display of the page which should not need to be this big in order to show this impossibly long, long, long, oh so long string' }
      let(:short_name) { 'Nice Short Name' }
      let(:actor)      { described_class.new(file_set, user) }

      before do
        allow(CharacterizeJob).to receive(:perform_later)
        allow(file_set).to receive(:label).and_return(short_name)
        # TODO: we should allow/expect call to IngestJob
        actor.create_content(fixture_file_upload(file))
      end

      subject { file_set.title }

      it { is_expected.to eql [short_name] }
    end

    context 'when a label is already specified' do
      let(:file)     { 'world.png' }
      let(:label)    { 'test_file.png' }
      let(:file_set_with_label) do
        FileSet.new do |f|
          f.apply_depositor_metadata(user.user_key)
          f.label = label
        end
      end
      let(:actor) { described_class.new(file_set_with_label, user) }

      before do
        allow(IngestFileJob).to receive(:perform_later)
        allow(CharacterizeJob).to receive(:perform_later)
        actor.create_content(fixture_file_upload(file))
      end

      it "retains the object's original label" do
        expect(file_set_with_label.label).to eql(label)
      end
    end
  end

  describe "#update_metadata" do
    it "is successful" do
      expect(actor.update_metadata("title" => ["updated title"])).to be true
      expect(file_set.reload.title).to eq ["updated title"]
    end
  end

  describe "#destroy" do
    it "destroys the object" do
      actor.destroy
      expect { file_set.reload }.to raise_error ActiveFedora::ObjectNotFoundError
    end

    context "representative and thumbnail of a work" do
      let!(:work) do
        work = create(:generic_work)
        # this is not part of a block on the create, since the work must be saved
        # before the representative can be assigned
        work.ordered_members << file_set
        work.representative = file_set
        work.thumbnail = file_set
        work.save
        work
      end

      it "removes representative, thumbnail, and the proxy association" do
        gw = GenericWork.load_instance_from_solr(work.id)
        expect(gw.representative_id).to eq(file_set.id)
        expect(gw.thumbnail_id).to eq(file_set.id)
        expect { actor.destroy }.to change { ActiveFedora::Aggregation::Proxy.count }.by(-1)
        gw = GenericWork.load_instance_from_solr(work.id)
        expect(gw.representative_id).to be_nil
        expect(gw.thumbnail_id).to be_nil
      end
    end
  end

  describe "#attach_file_to_work" do
    before do
      # stub out redis connection
      client = double('redlock client')
      allow(client).to receive(:lock).and_yield(true)
      allow(Redlock::Client).to receive(:new).and_return(client)
    end

    let(:file_set2) { create(:file_set) }
    let(:file_set3) { create(:file_set) }

    # The first version of the work has a single member.
    let!(:work_v1) do
      work = create(:generic_work)
      work.ordered_members << file_set
      work.save
      work
    end

    # Create another version of the same work with a second member.
    let!(:work_v2) do
      work = ActiveFedora::Base.find(work_v1.id)
      work.ordered_members << file_set2
      work.save
      work
    end

    it "writes to the most up to date version" do
      expect(CurationConcerns.config.callback).to receive(:run).with(:after_create_fileset, file_set3, user)
      # using send(), because attach_file_to_work is private
      actor.send(:attach_file_to_work, work_v1, file_set3, {})
      expect(work_v1.members.size).to eq 3
    end
  end

  describe "#set_representative" do
    let!(:work) { build(:generic_work, representative: rep) }
    let!(:file_set) { build(:file_set) }

    before do
      actor.send(:set_representative, work, file_set)
    end

    context "when the representative isn't set" do
      let(:rep) { nil }

      it 'sets the representative' do
        expect(work.representative).to eq file_set
      end
    end

    context 'when the representative is already set' do
      let(:rep) { build(:file_set, id: '123') }

      it 'keeps the existing representative' do
        expect(work.representative).to eq rep
      end
    end
  end

  describe "#set_thumbnail" do
    let!(:work) { build(:generic_work, thumbnail: thumb) }
    let!(:file_set) { build(:file_set) }

    before do
      actor.send(:set_thumbnail, work, file_set)
    end

    context "when the thumbnail isn't set" do
      let(:thumb) { nil }

      it 'sets the thumbnail' do
        expect(work.thumbnail).to eq file_set
      end
    end

    context 'when the thumbnail is already set' do
      let(:thumb) { build(:file_set, id: '123') }

      it 'keeps the existing thumbnail' do
        expect(work.thumbnail).to eq thumb
      end
    end
  end

  describe "#file_actor_class" do
    context "default" do
      it "is a FileActor" do
        expect(actor.file_actor_class).to eq(CurationConcerns::FileActor)
      end
    end

    context "overridden" do
      let(:actor) { CustomFileSetActor.new(file_set, user) }

      before do
        class CustomFileActor < CurationConcerns::FileActor
        end
        class CustomFileSetActor < CurationConcerns::FileSetActor
          def file_actor_class
            CustomFileActor
          end
        end
      end

      after do
        Object.send(:remove_const, :CustomFileActor)
        Object.send(:remove_const, :CustomFileSetActor)
      end

      it "is a custom class" do
        expect(actor.file_actor_class).to eq(CustomFileActor)
      end
    end
  end
end
