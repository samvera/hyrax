require 'spec_helper'
require 'redlock'

describe Hyrax::Actors::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user)           { create(:user) }
  let(:uploaded_file)  { fixture_file_upload('/world.png', 'image/png') }
  let(:local_file)     { File.open(File.join(fixture_path, 'world.png')) }
  let(:file_set)       { create(:file_set, content: local_file) }
  let(:actor)          { described_class.new(file_set, user) }
  let(:ingest_options) { { mime_type: 'image/png', relation: 'original_file', filename: 'world.png' } }

  describe 'creating metadata, content and attaching to a work' do
    let(:upload_set_id) { nil }
    let(:work) { nil }
    subject { file_set.reload }
    let(:date_today) { DateTime.current }

    before do
      allow(DateTime).to receive(:current).and_return(date_today)
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png/, user, ingest_options)
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata
      actor.create_content(uploaded_file)
      actor.attach_file_to_work(work)
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
        expect(subject).not_to be_under_embargo
        expect(subject).not_to be_active_lease
        expect(subject.visibility).to eq 'restricted'
      end
    end
  end

  describe "#attach_file_to_work" do
    let(:work) { create(:public_generic_work) }

    it 'copies visibility from the parent' do
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.attach_file_to_work(work)
      saved_file = file_set.reload
      expect(saved_file.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  describe '#create_content' do
    it 'calls ingest file job' do
      expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png/, user, ingest_options)
      actor.create_content(uploaded_file)
    end

    context 'when an alternative relationship is specified' do
      let(:ingest_options) { { mime_type: 'image/png', relation: 'remastered', filename: 'world.png' } }
      it 'calls ingest file job' do
        expect(IngestFileJob).to receive(:perform_later).with(file_set, /world\.png/, user, ingest_options)
        actor.create_content(uploaded_file, 'remastered')
      end
    end

    context 'using ::File' do
      before do
        allow(IngestFileJob).to receive(:perform_later)
        actor.create_content(local_file)
      end

      it 'sets the label and title' do
        expect(file_set.label).to eq(File.basename(local_file))
        expect(file_set.title).to eq([File.basename(local_file)])
      end

      it 'gets the mime_type from original_file' do
        expect(file_set.mime_type).to eq('image/png')
      end
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:file)       { 'world.png' }
      let(:long_name)  do
        'an absurdly long title that goes on way to long and ' \
                         'messes up the display of the page which should not need ' \
                         'to be this big in order to show this impossibly long, ' \
                         'long, long, oh so long string'
      end
      let(:short_name) { 'Nice Short Name' }
      let(:actor)      { described_class.new(file_set, user) }

      before do
        allow(IngestFileJob).to receive(:perform_later)
        allow(file_set).to receive(:label).and_return(short_name)
        # TODO: we should allow/expect call to IngestJob
        actor.create_content(fixture_file_upload(file))
      end

      subject { file_set.title }

      it { is_expected.to match_array [short_name] }
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

  describe "#update_content" do
    let(:relation) { 'original_file' }
    let(:file_actor) { Hyrax::Actors::FileActor.new(file_set, relation, user) }
    before do
      allow(actor).to receive(:build_file_actor).with(relation).and_return(file_actor)
    end
    it 'calls ingest_file' do
      expect(file_actor).to receive(:ingest_file).with(local_file, true)
      actor.update_content(local_file)
    end
    it 'runs callbacks' do
      # Do not bother ingesting the file -- test only that the callback is run
      allow(file_actor).to receive(:ingest_file).with(local_file, true)
      expect(Hyrax.config.callback).to receive(:run).with(:after_update_content, file_set, user)
      actor.update_content(local_file)
    end
    it "returns true" do
      # Do not bother ingesting the file -- test only the return value
      allow(file_actor).to receive(:ingest_file).with(local_file, true)
      expect(actor.update_content(local_file)).to be true
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
        gw = GenericWork.find(work.id)
        expect(gw.representative_id).to eq(file_set.id)
        expect(gw.thumbnail_id).to eq(file_set.id)
        expect { actor.destroy }.to change { ActiveFedora::Aggregation::Proxy.count }.by(-1)
        gw = GenericWork.find(work.id)
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

    # The first version of the work has no members.
    let!(:work_v1) { create(:generic_work) }

    # Create another version of the same work with a member.
    let!(:work_v2) do
      work = ActiveFedora::Base.find(work_v1.id)
      work.ordered_members << create(:file_set)
      work.save
      work
    end

    it "writes to the most up to date version" do
      actor.attach_file_to_work(work_v1, {})
      expect(work_v1.members.size).to eq 2
    end
  end

  describe "#assign_visibility?" do
    context "when no params are specified" do
      it "does not need to assign visibility" do
        expect(actor.send(:assign_visibility?)).to eq false
      end
    end

    context "when file set params with visibility are specified with symbols as keys" do
      let(:file_set_params) { { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it "does need to assign visibility" do
        expect(actor.send(:assign_visibility?, file_set_params)).to eq true
      end
    end

    context "when file set params with visibility are specified with strings as keys" do
      let(:file_set_params) { { "visibility" => Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC } }

      it "does need to assign visibility" do
        expect(actor.send(:assign_visibility?, file_set_params)).to eq true
      end
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
        expect(actor.file_actor_class).to eq(Hyrax::Actors::FileActor)
      end
    end

    context "overridden" do
      let(:actor) { CustomFileSetActor.new(file_set, user) }

      before do
        class CustomFileActor < Hyrax::Actors::FileActor
        end
        class CustomFileSetActor < Hyrax::Actors::FileSetActor
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

  describe '#revert_content' do
    let(:file_set) { create(:file_set, user: user) }
    let(:file1)    { "small_file.txt" }
    let(:file2)    { "hyrax_generic_stub.txt" }
    let(:version1) { "version1" }

    before do
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :inline
      allow(CharacterizeJob).to receive(:perform_later)
      actor.create_content(fixture_file_upload(file1))
      actor.create_content(fixture_file_upload(file2))
      ActiveJob::Base.queue_adapter = original_adapter
      actor.file_set.reload
    end

    let(:restored_content) { file_set.reload.original_file }

    it "restores the first versions's content and metadata" do
      actor.revert_content(version1)
      expect(restored_content.original_name).to eq file1
    end
  end
end
