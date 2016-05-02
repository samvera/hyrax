require 'spec_helper'

# This tests the FileSet model that is inserted into the host app by curation_concerns:models:install
# It includes the CurationConcerns::FileSetBehavior module and nothing else
# So this test covers both the FileSetBehavior module and the generated FileSet model
describe FileSet do
  let(:user) { create(:user) }

  describe 'rdf type' do
    subject { described_class.new.type }
    it { is_expected.to include(Hydra::PCDM::Vocab::PCDMTerms.Object, Hydra::Works::Vocab::WorksTerms.FileSet) }
  end

  it 'is a Hydra::Works::FileSet' do
    expect(subject).to be_file_set
  end

  it 'has depositor' do
    subject.depositor = 'tess@example.com'
  end

  it 'updates attributes' do
    subject.attributes = { title: ['My new Title'] }
    expect(subject.title).to eq(['My new Title'])
  end

  context 'when it is initialized' do
    it 'has empty arrays for all the properties' do
      subject.attributes.each do |_k, v|
        expect(Array(v)).to eq([])
      end
    end
  end

  describe 'visibility' do
    it "does not be changed when it's new" do
      expect(subject).not_to be_visibility_changed
    end
    it 'is changed when it has been changed' do
      subject.visibility = 'open'
      expect(subject).to be_visibility_changed
    end

    it "does not be changed when it's set to its previous value" do
      subject.visibility = 'restricted'
      expect(subject).not_to be_visibility_changed
    end
  end

  describe '#apply_depositor_metadata' do
    before { subject.apply_depositor_metadata('jcoyne') }

    it 'grants edit access and record the depositor' do
      expect(subject.edit_users).to eq ['jcoyne']
      expect(subject.depositor).to eq 'jcoyne'
    end
  end

  describe 'attributes' do
    it 'has a set of permissions' do
      subject.read_groups = %w(group1 group2)
      subject.edit_users = ['user1']
      subject.read_users = %w(user2 user3)
      expect(subject.permissions.map(&:to_hash)).to match_array [
        { type: 'group', access: 'read', name: 'group1' },
        { type: 'group', access: 'read', name: 'group2' },
        { type: 'person', access: 'read', name: 'user2' },
        { type: 'person', access: 'read', name: 'user3' },
        { type: 'person', access: 'edit', name: 'user1' }]
    end

    it "has attached content" do
      expect(subject.association(:original_file)).to be_kind_of ActiveFedora::Associations::DirectlyContainsOneAssociation
    end
  end

  describe 'metadata' do
    it 'has descriptive metadata' do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:part_of)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:rights)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
    it 'has properties from characterization metadata' do
      expect(subject).to respond_to(:format_label)
      expect(subject).to respond_to(:mime_type)
      expect(subject).to respond_to(:file_size)
      expect(subject).to respond_to(:last_modified)
      expect(subject).to respond_to(:filename)
      expect(subject).to respond_to(:original_checksum)
      expect(subject).to respond_to(:well_formed)
      expect(subject).to respond_to(:page_count)
      expect(subject).to respond_to(:file_title)
      expect(subject).to respond_to(:creator)
    end

    it 'redefines to_param to make redis keys more recognizable' do
      expect(subject.to_param).to eq subject.id
    end

    describe 'that have been saved' do
      before { subject.apply_depositor_metadata('jcoyne') }

      it 'is able to set values via delegated methods' do
        subject.related_url = ['http://example.org/']
        subject.creator = ['John Doe']
        subject.title = ['New work']
        subject.save
        f = subject.reload
        expect(f.related_url).to eq ['http://example.org/']
        expect(f.creator).to eq ['John Doe']
        expect(f.title).to eq ['New work']
      end

      it 'is able to be added to w/o unexpected graph behavior' do
        subject.creator = ['John Doe']
        subject.title = ['New work']
        subject.save!
        f = subject.reload
        expect(f.creator).to eq ['John Doe']
        expect(f.title).to eq ['New work']
        f.creator = ['Jane Doe']
        f.title += ['Newer work']
        f.save
        f = subject.reload
        expect(f.creator).to eq ['Jane Doe']
        # TODO: Is order important?
        expect(f.title).to include('New work')
        expect(f.title).to include('Newer work')
      end
    end
  end

  describe '#indexer' do
    subject { described_class.indexer }
    it { is_expected.to eq CurationConcerns::FileSetIndexer }
  end

  it 'supports multi-valued fields in solr' do
    subject.tag = %w(tag1 tag2)
    expect { subject.save }.not_to raise_error
    subject.delete
  end

  it 'supports setting and getting the relative_path value' do
    subject.relative_path = 'documents/research/NSF/2010'
    expect(subject.relative_path).to eq 'documents/research/NSF/2010'
  end
  describe 'create_thumbnail' do
    before do
      @f = described_class.new
      @f.apply_depositor_metadata('mjg36')
    end
    describe 'with a video', if: CurationConcerns.config.enable_ffmpeg do
      before do
        allow(@f).to receive(mime_type: 'video/quicktime') # Would get set by the characterization job
        @f.save
        Hydra::Works::AddFileToFileSet.call(subject, File.open("#{fixture_path}/countdown.avi", 'rb'), :original_file)
      end
      it 'makes a png thumbnail' do
        @f.create_thumbnail
        expect(@f.thumbnail.content.size).to eq 4768 # this is a bad test. I just want to show that it did something.
        expect(@f.thumbnail.mime_type).to eq 'image/png'
      end
    end
  end

  describe '#related_files' do
    let!(:f1) { described_class.new }

    context 'when there are no related files' do
      it 'returns an empty array' do
        expect(f1.related_files).to eq []
      end
    end

    context 'when there are related files' do
      let(:parent_work)   { FactoryGirl.create(:work_with_files) }
      let(:f1)            { parent_work.file_sets.first }
      let(:f2)            { parent_work.file_sets.last }
      subject { f1.reload.related_files }
      it 'returns all files contained in parent work(s) but excludes itself' do
        expect(subject).to include(f2)
        expect(subject).to_not include(f1)
      end
    end
  end

  describe 'noid integration' do
    before do
      allow_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).and_return(noid)
    end

    let(:noid) { 'wd3763094' }

    subject do
      described_class.create { |f| f.apply_depositor_metadata('mjg36') }
    end

    it 'runs the overridden #assign_id method' do
      expect_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).once
      described_class.create { |f| f.apply_depositor_metadata('mjg36') }
    end

    it 'returns the expected identifier' do
      expect(subject.id).to eq noid
    end

    it "has a treeified URL" do
      expect(subject.uri.to_s).to end_with '/wd/37/63/09/wd3763094'
    end

    context 'when a url is provided' do
      let(:url) { "#{ActiveFedora.fedora.host}/test/wd/37/63/09/wd3763094" }

      it 'transforms the url into an id' do
        expect(described_class.uri_to_id(url)).to eq 'wd3763094'
      end
    end
  end

  context 'with access control metadata' do
    subject do
      described_class.new do |m|
        m.apply_depositor_metadata('jcoyne')
        m.permissions_attributes = [{ type: 'person', access: 'read', name: 'person1' },
                                    { type: 'person', access: 'read', name: 'person2' },
                                    { type: 'group', access: 'read', name: 'group-6' },
                                    { type: 'group', access: 'read', name: 'group-7' },
                                    { type: 'group', access: 'edit', name: 'group-8' }]
      end
    end

    it 'has read groups accessor' do
      expect(subject.read_groups).to eq ['group-6', 'group-7']
    end

    it 'has read groups writer' do
      subject.read_groups = ['group-2', 'group-3']
      expect(subject.read_groups).to eq ['group-2', 'group-3']
    end

    it 'has read groups string writer' do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      expect(subject.read_groups).to eq ['umg/up.dlt.staff', 'group-3']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to eq %w(person1 person2)
      expect(subject.edit_users).to eq ['jcoyne']
    end

    it 'revokes only eligible groups' do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.read_groups).to match_array ['group-2', 'group-3', 'group-7']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to match_array %w(person1 person2)
      expect(subject.edit_users).to eq ['jcoyne']
    end
  end

  describe 'permissions validation' do
    before { subject.apply_depositor_metadata('mjg36') }

    describe 'overriding' do
      let(:asset) { SampleKlass.new }
      before do
        class SampleKlass < FileSet
          def paranoid_edit_permissions
            []
          end
        end
        asset.apply_depositor_metadata('mjg36')
      end
      after do
        Object.send(:remove_const, :SampleKlass)
      end
      context 'when the public has edit access' do
        before { subject.edit_groups = ['public'] }

        it 'is invalid' do
          expect(subject).to_not be_valid
          expect(subject.errors[:edit_groups]).to include('Public cannot have edit access')
        end
      end
    end

    context 'when the depositor does not have edit access' do
      before do
        subject.permissions = [Hydra::AccessControls::Permission.new(type: 'person', name: 'mjg36', access: 'read')]
      end
      it 'is invalid' do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_users]).to include('Depositor must have edit access')
      end
    end

    context 'when the public has edit access' do
      before { subject.edit_groups = ['public'] }

      it 'is invalid' do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_groups]).to include('Public cannot have edit access')
      end
    end

    context 'when registered has edit access' do
      before { subject.edit_groups = ['registered'] }

      it 'is invalid' do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_groups]).to include('Registered cannot have edit access')
      end
    end

    context 'everything is copacetic' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe 'file content validation' do
    subject { create(:file_set) }
    let(:file_path) { fixture_path + '/small_file.txt' }

    context 'when file contains a virus' do
      before do
        allow(subject).to receive(:warn) # suppress virus warnings
        allow(ClamAV.instance).to receive(:scanfile).and_return('EL CRAPO VIRUS')
        # TODO: Test that this works with Hydra::Works::UploadFileToFileSet. see https://github.com/projecthydra-labs/hydra-works/pull/139
        # Hydra::Works::UploadFileToFileSet.call(subject, file_path, original_name: 'small_file.txt')
        of = subject.build_original_file
        of.content = File.open(file_path)
      end

      it 'populates the errors hash during validation' do
        expect(subject).to_not be_valid
        expect(subject.errors.messages[:base].first).to match(/A virus was found in .*: EL CRAPO VIRUS/)
      end

      it 'does not save the file or create a new version' do
        original_version_count = subject.versions.count
        subject.save
        expect(subject.versions.count).to eq original_version_count
        expect(subject.reload.original_file).to be_nil
      end
    end
  end

  describe '#where_digest_is' do
    let(:file) { create(:file_set) }
    let(:file_path) { fixture_path + '/small_file.txt' }
    let(:digest_string) { '88fb4e88c15682c18e8b19b8a7b6eaf8770d33cf' }
    before do
      allow(file).to receive(:warn) # suppress virus warnings
      of = file.build_original_file
      of.content = File.open(file_path)
      file.save
      file.update_index
    end
    subject { described_class.where_digest_is(digest_string).first }
    it { is_expected.to eq(file) }
  end

  describe 'to_solr' do
    let(:indexer) { double(generate_solr_document: {}) }
    before do
      allow(CurationConcerns::FileSetIndexer).to receive(:new)
        .with(subject).and_return(indexer)
    end

    it 'calls the indexer' do
      expect(indexer).to receive(:generate_solr_document)
      subject.to_solr
    end

    it 'has human readable type' do
      expect(subject.to_solr.fetch('human_readable_type_tesim')).to eq 'File'
    end
  end

  context 'with versions' do
    it 'has versions' do
      expect(subject.versions.count).to eq 0
    end
  end

  describe 'public?' do
    context 'when read group is set to public' do
      before { subject.read_groups = ['public'] }

      it { is_expected.to be_public }
    end

    context 'when read group is not set to public' do
      before { subject.read_groups = ['foo'] }
      it { is_expected.not_to be_public }
    end
  end

  describe 'work associations' do
    let(:work) { create(:work_with_one_file) }
    subject { work.file_sets.first.reload }
    it 'belongs to works' do
      expect(subject.parents).to eq [work]
    end
  end

  describe '#to_s' do
    it 'uses the provided titles' do
      subject.title = %w(Hello World)
      expect(subject.to_s).to eq('Hello | World')
    end

    it 'falls back on label if no titles are given' do
      subject.title = []
      subject.label = 'Spam'
      expect(subject.to_s).to eq('Spam')
    end

    it 'with no label or titles it is "No Title"' do
      subject.title = []
      subject.label = nil
      expect(subject.to_s).to eq('No Title')
    end
  end

  describe 'to_solr record' do
    let(:depositor) { 'jcoyne' }
    subject do
      described_class.new.tap do |f|
        f.apply_depositor_metadata(depositor)
        f.save
      end
    end
    let(:depositor_key) { Solrizer.solr_name('depositor') }
    let(:title_key) { Solrizer.solr_name('title', :stored_searchable, type: :string) }
    let(:title) { ['abc123'] }
    let(:no_terms) { described_class.find(subject.id).to_solr }
    let(:terms) do
      file = described_class.find(subject.id)
      file.title = title
      file.save
      file.to_solr
    end

    context 'without terms' do
      specify 'title is nil' do
        expect(no_terms[title_key]).to be_nil
      end
    end

    context 'with terms' do
      specify 'depositor is set' do
        expect(terms[depositor_key].first).to eql(depositor)
      end
      specify 'title is set' do
        expect(terms[title_key]).to eql(title)
      end
    end
  end

  describe 'assign_id' do
    context 'with noids enabled (by default)' do
      it 'uses the noid service' do
        expect_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).once
        subject.assign_id
      end
    end

    context 'with noids disabled' do
      before { CurationConcerns.config.enable_noids = false }
      after { CurationConcerns.config.enable_noids = true }

      it 'does not use the noid service' do
        expect_any_instance_of(ActiveFedora::Noid::Service).not_to receive(:mint)
        subject.assign_id
      end
    end
  end

  describe 'with a parent work' do
    let(:parent) { create(:work_with_one_file) }
    let(:parent_id) { parent.id }

    describe '#related_files' do
      let(:parent) { create(:work_with_files) }
      let(:sibling) { parent.file_sets.last }
      subject { parent.file_sets.first.reload }
      it 'returns related files, but not itself' do
        expect(subject.related_files).to eq([sibling])
        expect(sibling.reload.related_files).to eq([subject])
      end
    end

    describe '#remove_representative_relationship' do
      subject { parent.file_sets.first.reload }

      context 'it is not the representative' do
        let(:some_other_id) { create(:file_set).id }
        before do
          parent.representative_id = some_other_id
          parent.save!
        end

        it "doesn't update parent work when file is deleted" do
          subject.destroy
          expect(parent.representative_id).to eq some_other_id
        end
      end

      context 'it is the representative' do
        before do
          parent.representative_id = subject.id
          parent.save!
        end

        it 'updates the parent work when the file is deleted' do
          subject.destroy
          expect(parent.reload.representative_id).to be_nil
        end
      end
    end
  end

  describe 'mime type recognition' do
    context '#image?' do
      context 'when image/jp2' do
        before { subject.mime_type = 'image/jp2' }
        it { should be_image }
      end
      context 'when image/jpg' do
        before { subject.mime_type = 'image/jpg' }
        it { should be_image }
      end
      context 'when image/png' do
        before { subject.mime_type = 'image/png' }
        it { should be_image }
      end
      context 'when image/tiff' do
        before { subject.mime_type = 'image/tiff' }
        it { should be_image }
      end
    end

    describe '#pdf?' do
      before { subject.mime_type = 'application/pdf' }
      it { should be_pdf }
    end

    describe '#audio?' do
      context 'when x-wave' do
        before { subject.mime_type = 'audio/x-wave' }
        it { should be_audio }
      end
      context 'when x-wav' do
        before { subject.mime_type = 'audio/x-wav' }
        it { should be_audio }
      end
      context 'when mpeg' do
        before { subject.mime_type = 'audio/mpeg' }
        it { should be_audio }
      end
      context 'when mp3' do
        before { subject.mime_type = 'audio/mp3' }
        it { should be_audio }
      end
      context 'when ogg' do
        before { subject.mime_type = 'audio/ogg' }
        it { should be_audio }
      end
    end

    describe '#video?' do
      context 'should be true for avi' do
        before { subject.mime_type = 'video/avi' }
        it { should be_video }
      end

      context 'should be true for webm' do
        before { subject.mime_type = 'video/webm' }
        it { should be_video }
      end
      context 'should be true for mp4' do
        before { subject.mime_type = 'video/mp4' }
        it { should be_video }
      end
      context 'should be true for mpeg' do
        before { subject.mime_type = 'video/mpeg' }
        it { should be_video }
      end
      context 'should be true for quicktime' do
        before { subject.mime_type = 'video/quicktime' }
        it { should be_video }
      end
      context 'should be true for mxf' do
        before { subject.mime_type = 'application/mxf' }
        it { should be_video }
      end
    end
  end

  describe "#to_global_id" do
    let(:file_set) { described_class.new(id: '123') }
    subject { file_set.to_global_id }
    it { is_expected.to be_kind_of GlobalID }
  end
end
