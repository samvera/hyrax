require 'spec_helper'

describe CurationConcerns::GenericFileActor do
  include ActionDispatch::TestProcess

  let(:user) { FactoryGirl.create(:user) }
  let(:generic_file) { FactoryGirl.create(:generic_file) }
  let(:actor) { described_class.new(generic_file, user) }
  let(:uploaded_file) { fixture_file_upload('/world.png', 'image/png') }

  describe 'creating metadata and content' do
    let(:batch_id) { nil }
    let(:work_id) { nil }
    subject { generic_file.reload }
    before do
      allow(actor).to receive(:save_characterize_and_record_committer).and_return('true')
      actor.create_metadata(batch_id, work_id)
      actor.create_content(uploaded_file)
    end
    context 'when a work_id is provided' do
      let(:work) { FactoryGirl.create(:generic_work) }
      let(:work_id) { work.id }
      it 'adds the generic file to the parent work' do
        expect(subject.generic_works).to eq [work]
        expect(work.reload.generic_files).to include(subject)
      end
    end
  end

  describe '#create_content' do
    let(:deposit_message) { double('deposit message') }
    let(:characterize_message) { double('characterize message') }
    before do
      allow(CurationConcerns.queue).to receive(:push)
    end

    it 'uses the provided mime_type' do
      actor.create_content(uploaded_file)
      expect(generic_file.original_file.mime_type).to eq 'image/png'
    end

    context 'when generic_file.title is empty and generic_file.label is not' do
      let(:file)       { 'world.png' }
      let(:long_name)  { 'an absurdly long title that goes on way to long and messes up the display of the page which should not need to be this big in order to show this impossibly long, long, long, oh so long string' }
      let(:short_name) { 'Nice Short Name' }
      let(:actor)      { described_class.new(generic_file, user) }
      before do
        allow(generic_file).to receive(:label).and_return(short_name)
        allow(CurationConcerns.queue).to receive(:push)
        actor.create_content(fixture_file_upload(file))
      end
      subject { generic_file.title }
      it { is_expected.to eql [short_name] }
    end

    context 'with two existing versions from different users' do
      let(:file1)       { 'world.png' }
      let(:file2)       { 'small_file.txt' }
      let(:actor1)      { described_class.new(generic_file, user) }
      let(:actor2)      { described_class.new(generic_file, second_user) }

      let(:second_user) { FactoryGirl.find_or_create(:archivist) }
      let(:versions) { generic_file.original_file.versions }

      before do
        allow(CurationConcerns.queue).to receive(:push)
        actor1.create_content(fixture_file_upload(file1))
        actor2.create_content(fixture_file_upload(file2))
      end

      it 'has two versions' do
        expect(versions.all.count).to eq 2
      end

      it 'has the current version' do
        expect(CurationConcerns::VersioningService.latest_version_of(generic_file.original_file).label).to eq 'version2'
        expect(generic_file.original_file.content).to eq fixture_file_upload(file2).read
        expect(generic_file.original_file.mime_type).to eq 'text/plain'
        expect(generic_file.original_file.original_name).to eq file2
      end

      it "uses the first version for the object's title and label" do
        expect(generic_file.label).to eql(file1)
        expect(generic_file.title.first).to eql(file1)
      end

      it 'notes the user for each version' do
        expect(VersionCommitter.where(version_id: versions.first.uri).pluck(:committer_login)).to eq [user.user_key]
        expect(VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [second_user.user_key]
      end
    end
  end

  context 'when a label is already specified' do
    let(:label)    { 'test_file.png' }
    let(:new_file) { 'foo.jpg' }
    let(:generic_file_with_label) do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata(user.user_key)
        f.label = label
      end
    end
    let(:actor) { described_class.new(generic_file_with_label, user) }

    before do
      allow(actor).to receive(:save_characterize_and_record_committer).and_return('true')
      allow(Hydra::Works::UploadFileToGenericFile).to receive(:call)
      actor.create_content(Tempfile.new(new_file))
    end

    it "will retain the object's original label" do
      expect(generic_file_with_label.label).to eql(label)
    end
  end
end
