require 'spec_helper'
require 'redlock'

describe CurationConcerns::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:actor) { described_class.new(file_set, user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }

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
      expect(IngestFileJob).to receive(:perform_later).with(file_set.id, /world\.png$/, 'image/png', user.user_key)
      allow(actor).to receive(:acquire_lock_for).and_yield
      actor.create_metadata(upload_set_id, work)
      actor.create_content(uploaded_file)
    end

    context 'when an upload_set_id and work are not provided' do
      let(:upload_set_id) { nil }
      it "leaves the associations blank" do
        expect(subject.upload_set).to be_nil
        expect(subject.generic_works).to be_empty
      end
    end

    context 'when a upload_set_id is provided' do
      let(:upload_set_id) { ActiveFedora::Noid::Service.new.mint }
      it "leaves the association blank" do
        expect(subject.upload_set).to be_instance_of UploadSet
      end
    end

    context 'when a work is provided' do
      let(:work) { FactoryGirl.create(:generic_work) }

      it 'adds the generic file to the parent work' do
        expect(subject.generic_works).to eq [work]
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
      actor.create_metadata(nil, work)
      saved_file = file_set.reload
      expect(saved_file.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  describe '#create_content' do
    it 'calls ingest file job' do
      expect(CharacterizeJob).to receive(:perform_later)
      expect(IngestFileJob).to receive(:perform_later).with(file_set.id, /world\.png$/, 'image/png', user.user_key)
      actor.create_content(uploaded_file)
    end

    context 'when file_set.title is empty and file_set.label is not' do
      let(:file)       { 'world.png' }
      let(:long_name)  { 'an absurdly long title that goes on way to long and messes up the display of the page which should not need to be this big in order to show this impossibly long, long, long, oh so long string' }
      let(:short_name) { 'Nice Short Name' }
      let(:actor)      { described_class.new(file_set, user) }

      before do
        allow(CharacterizeJob).to receive(:perform_later)
        allow(file_set).to receive(:label).and_return(short_name)
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

  describe "#destroy" do
    it "destroys the object" do
      actor.destroy
      expect { file_set.reload }.to raise_error ActiveFedora::ObjectNotFoundError
    end
    context "representative of a work" do
      let!(:work) do
        work = create(:generic_work)
        # this is not part of a block on the create, since the work must be saved
        # before the representative can be assigned
        work.members << file_set
        work.representative = file_set
        work.save
        work
      end

      it "removes representative" do
        expect(work.reload.representative_id).to eq(file_set.id)
        actor.destroy
        expect(work.reload.representative_id).to be_nil
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
      # using send(), because attach_file_to_work is private
      actor.send(:attach_file_to_work, work_v1, file_set3, {})
      expect(work_v1.members.size).to eq 3
    end
  end
end
