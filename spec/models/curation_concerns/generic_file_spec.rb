require 'spec_helper'

describe CurationConcerns::GenericFile do

  let(:user) { FactoryGirl.find_or_create(:jill) }
  # subject {
  #   file = CurationConcerns::GenericFile.new
  #   file.apply_depositor_metadata(user.user_key)
  #   file
  # }

  describe "rdf type" do
    subject { described_class.new.type }
    it { is_expected.to include(RDFVocabularies::PCDMTerms.Object,WorksVocabularies::WorksTerms.GenericFile) }
  end

  it "is a Hydra::Works GenericFile" do
    expect(Hydra::Works.generic_file?(subject)).to be_truthy
  end

  it "should have depositor" do
    subject.depositor = 'tess@example.com'
  end

  it "should update attributes" do
    subject.attributes = {title:["My new Title"]}
    expect(subject.title).to eq(["My new Title"])
  end

  context "when it is initialized" do
    it "has empty arrays for all the properties" do
      subject.attributes.each do |k,v|
        expect(Array(v)).to eq([])
      end
    end
  end

  describe "visibility" do
    it "should not be changed when it's new" do
      expect(subject).not_to be_visibility_changed
    end
    it "should be changed when it has been changed" do
      subject.visibility= 'open'
      expect(subject).to be_visibility_changed
    end

    it "should not be changed when it's set to its previous value" do
      subject.visibility= 'restricted'
      expect(subject).not_to be_visibility_changed
    end

  end

  describe "#apply_depositor_metadata" do
    before { subject.apply_depositor_metadata('jcoyne') }

    it "should grant edit access and record the depositor" do
      expect(subject.edit_users).to eq ['jcoyne']
      expect(subject.depositor).to eq 'jcoyne'
    end
  end

  describe "attributes" do
    it "should have a set of permissions" do
      subject.read_groups=['group1', 'group2']
      subject.edit_users=['user1']
      subject.read_users=['user2', 'user3']
      expect(subject.permissions.map(&:to_hash)).to match_array [
                                                                    {type: "group", access: "read", name: "group1"},
                                                                    {type: "group", access: "read", name: "group2"},
                                                                    {type: "person", access: "read", name: "user2"},
                                                                    {type: "person", access: "read", name: "user3"},
                                                                    {type: "person", access: "edit", name: "user1"}]
    end

    it "should have a characterization datastream" do
      expect(subject.characterization).to be_kind_of FitsDatastream
    end

    it "should have attached content" do
      subject.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      expect(subject.content).to be_kind_of ActiveFedora::File
    end
  end

  describe "metadata" do
    it "should have descriptive metadata" do
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
    it "should delegate methods to characterization metadata" do
      expect(subject).to respond_to(:format_label)
      expect(subject).to respond_to(:mime_type)
      expect(subject).to respond_to(:file_size)
      expect(subject).to respond_to(:last_modified)
      expect(subject).to respond_to(:filename)
      expect(subject).to respond_to(:original_checksum)
      expect(subject).to respond_to(:well_formed)
      expect(subject).to respond_to(:file_title)
      expect(subject).to respond_to(:file_author)
      expect(subject).to respond_to(:page_count)
    end
    it "should redefine to_param to make redis keys more recognizable" do
      expect(subject.to_param).to eq subject.id
    end

    describe "that have been saved" do
      before { subject.apply_depositor_metadata('jcoyne') }

      it "should have activity stream-related methods defined" do
        subject.save!
        f = subject.reload
        expect(f).to respond_to(:stream)
        expect(f).to respond_to(:events)
        expect(f).to respond_to(:create_event)
        expect(f).to respond_to(:log_event)
      end

      it "should be able to set values via delegated methods" do
        subject.related_url = ["http://example.org/"]
        subject.creator = ["John Doe"]
        subject.title = ["New work"]
        subject.save
        f = subject.reload
        expect(f.related_url).to eq ["http://example.org/"]
        expect(f.creator).to eq ["John Doe"]
        expect(f.title).to eq ["New work"]
      end

      it "should be able to be added to w/o unexpected graph behavior" do
        subject.creator = ["John Doe"]
        subject.title = ["New work"]
        subject.save!
        f = subject.reload
        expect(f.creator).to eq ["John Doe"]
        expect(f.title).to eq ["New work"]
        f.creator = ["Jane Doe"]
        f.title += ["Newer work"]
        f.save
        f = subject.reload
        expect(f.creator).to eq ["Jane Doe"]
        # TODO: Is order important?
        expect(f.title).to include("New work")
        expect(f.title).to include("Newer work")
      end
    end
  end

  describe "#indexer" do
    subject { described_class.indexer }
    it { is_expected.to eq Sufia::GenericFileIndexingService }
  end

  it "should support multi-valued fields in solr" do
    subject.tag = ["tag1", "tag2"]
    expect { subject.save }.not_to raise_error
    subject.delete
  end

  it "should support setting and getting the relative_path value" do
    subject.relative_path = "documents/research/NSF/2010"
    expect(subject.relative_path).to eq "documents/research/NSF/2010"
  end
  describe "create_thumbnail" do
    before do
      @f = CurationConcerns::GenericFile.new
      @f.apply_depositor_metadata('mjg36')
    end
    describe "with a video", if: Sufia.config.enable_ffmpeg do
      before do
        allow(@f).to receive(mime_type: 'video/quicktime')  #Would get set by the characterization job
        @f.add_file(File.open("#{fixture_path}/countdown.avi", 'rb'), path: 'content', original_name: 'countdown.avi')
        @f.save
      end
      it "should make a png thumbnail" do
        @f.create_thumbnail
        expect(@f.thumbnail.content.size).to eq 4768 # this is a bad test. I just want to show that it did something.
        expect(@f.thumbnail.mime_type).to eq 'image/png'
      end
    end
  end

  describe "#related_files" do
    let!(:f1) do
      CurationConcerns::GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end
    let!(:f2) do
      CurationConcerns::GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end
    let!(:f3) do
      CurationConcerns::GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end

    context "when the files belong to a batch" do
      let(:batch) { Batch.create }
      let(:batch_id) { batch.id }

      context "related_files" do
        it "should return related files and not return itself" do
          expect(f1.related_files).to match_array [f2, f3]
          expect(f2.related_files).to match_array [f1, f3]
          expect(f3.related_files).to match_array [f1, f2]
        end
      end
    end

    context "when there are no related files" do
      let(:batch_id) { nil }

      it "should return an empty array when there are no related files" do
        expect(f1.related_files).to eq []
      end
    end
  end

  describe "noid integration" do
    before do
      allow_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).and_return(noid)
    end

    let(:noid) { 'wd3763094' }

    subject do
      CurationConcerns::GenericFile.create { |f| f.apply_depositor_metadata('mjg36') }
    end

    it "runs the overridden #assign_id method" do
      expect_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).once
      CurationConcerns::GenericFile.create { |f| f.apply_depositor_metadata('mjg36') }
    end

    it "returns the expected identifier" do
      expect(subject.id).to eq noid
    end

    it "has a treeified URL" do
      expect(subject.uri).to eq 'http://localhost:8983/fedora/rest/test/wd/37/63/09/wd3763094'
    end

    context "when a url is provided" do
      let(:url) { 'http://localhost:8983/fedora/rest/test/wd/37/63/09/wd3763094' }

      it "transforms the url into an id" do
        expect(CurationConcerns::GenericFile.uri_to_id(url)).to eq 'wd3763094'
      end
    end
  end

  context "with access control metadata" do
    subject do
      CurationConcerns::GenericFile.new do |m|
        m.apply_depositor_metadata('jcoyne')
        m.permissions_attributes = [{type: 'person', access: 'read', name: "person1"},
                                    {type: 'person', access: 'read', name: "person2"},
                                    {type: 'group', access: 'read', name: "group-6"},
                                    {type: 'group', access: 'read', name: "group-7"},
                                    {type: 'group', access: 'edit', name: "group-8"}]
      end
    end

    it "should have read groups accessor" do
      expect(subject.read_groups).to eq ['group-6', 'group-7']
    end

    it "should have read groups string accessor" do
      expect(subject.read_groups_string).to eq 'group-6, group-7'
    end

    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      expect(subject.read_groups).to eq ['group-2', 'group-3']
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      expect(subject.read_groups).to eq ['umg/up.dlt.staff', 'group-3']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to eq ['person1', 'person2']
      expect(subject.edit_users).to eq ['jcoyne']
    end

    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.read_groups).to match_array ['group-2', 'group-3', 'group-7']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to match_array ['person1', 'person2']
      expect(subject.edit_users).to eq ['jcoyne']
    end
  end

  describe "permissions validation" do
    before { subject.apply_depositor_metadata('mjg36') }

    describe "overriding" do
      let(:asset) { SampleKlass.new }
      before do
        class SampleKlass < GenericFile
          def paranoid_edit_permissions
            []
          end
        end
        asset.apply_depositor_metadata('mjg36')
      end
      after do
        Object.send(:remove_const, :SampleKlass)
      end
      context "when the public has edit access" do
        before { subject.edit_groups = ['public'] }

        it "should be invalid" do
          expect(subject).to_not be_valid
          expect(subject.errors[:edit_groups]).to include('Public cannot have edit access')
        end
      end
    end

    context "when the depositor does not have edit access" do
      before do
        subject.permissions = [ Hydra::AccessControls::Permission.new(type: 'person', name: 'mjg36', access: 'read')]
      end
      it "should be invalid" do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_users]).to include('Depositor must have edit access')
      end
    end

    context "when the public has edit access" do
      before { subject.edit_groups = ['public'] }

      it "should be invalid" do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_groups]).to include('Public cannot have edit access')
      end
    end

    context "when registered has edit access" do
      before { subject.edit_groups = ['registered'] }

      it "should be invalid" do
        expect(subject).to_not be_valid
        expect(subject.errors[:edit_groups]).to include('Registered cannot have edit access')
      end
    end

    context "everything is copacetic" do
      it "should be valid" do
        expect(subject).to be_valid
      end
    end
  end

  describe "file content validation" do
    context "when file contains a virus" do
      let(:f) { File.new(fixture_path + '/small_file.txt') }

      before do
        subject.add_file(f, path: 'content', original_name: 'small_file.txt')
        subject.apply_depositor_metadata('mjg36')
      end

      it "populates the errors hash during validation" do
        allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError, "A virus was found in #{f.path}: EL CRAPO VIRUS")
        subject.save
        expect(subject).not_to be_persisted
        expect(subject.errors.messages).to eq(base: ["A virus was found in #{f.path}: EL CRAPO VIRUS"])
      end

      it "does not save a new version of a GenericFile" do
        subject.save!
        allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError)
        subject.add_file(File.new(fixture_path + '/sufia_generic_stub.txt') , path: 'content', original_name: 'sufia_generic_stub.txt')
        subject.save
        expect(subject.reload.content.content).to eq "small\n"
      end
    end
  end



  describe "to_solr" do
    before do
      subject.title = ['One Flew Over the Cuckoo\'s Nest']
      subject.characterization.height = '500'
      subject.characterization.width = '600'
    end
    let(:solr_doc) { subject.to_solr }

    it "has a solr_doc" do
      expect(solr_doc['title_tesim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['title_sim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['height_isi']).to eq 500
      expect(solr_doc['width_isi']).to eq 600
    end
  end

  context "with versions" do
    it "should have versions" do
      expect(subject.versions.count).to eq 0
    end
  end

  describe "public?" do
    context "when read group is set to public" do
      before { subject.read_groups = ['public'] }
      it { is_expected.to be_public }
    end

    context "when read group is not set to public" do
      before { subject.read_groups = ['foo'] }
      it { is_expected.not_to be_public }
    end
  end

  describe "work associations" do
    let(:work) { GenericWork.new }
    subject { CurationConcerns::GenericFile.new(generic_work: work) }

    it "should belong to works" do
      expect(subject.generic_work).to eq work
    end
  end

  describe '#to_s' do
    it 'uses the provided titles' do
      subject.title = ["Hello", "World"]
      expect(subject.to_s).to eq("Hello | World")
    end

    it 'falls back on label if no titles are given' do
      subject.title = []
      subject.label = 'Spam'
      expect(subject.to_s).to eq("Spam")
    end

    it 'with no label or titles it is "No Title"' do
      subject.title = []
      subject.label = nil
      expect(subject.to_s).to eq("No Title")
    end
  end

  describe "to_solr record" do
    let(:depositor) { 'jcoyne' }
    subject do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata(depositor)
        f.save
      end
    end
    let(:depositor_key) { Solrizer.solr_name("depositor") }
    let(:title_key) { Solrizer.solr_name("title", :stored_searchable, type: :string) }
    let(:title) { ["abc123"] }
    let(:no_terms) { GenericFile.find(subject.id).to_solr }
    let(:terms) {
      file = GenericFile.find(subject.id)
      file.title = title
      file.save
      file.to_solr
    }

    context "without terms" do
      specify "title is nil" do
        expect(no_terms[title_key]).to be_nil
      end
    end

    context "with terms" do
      specify "depositor is set" do
        expect(terms[depositor_key].first).to eql(depositor)
      end
      specify "title is set" do
        expect(terms[title_key]).to eql(title)
      end
    end

  end

  describe "assign_id" do
    context "with noids enabled (by default)" do
      it "uses the noid service" do
        expect_any_instance_of(ActiveFedora::Noid::Service).to receive(:mint).once
        subject.assign_id
      end
    end

    context "with noids disabled" do
      before { Sufia.config.enable_noids = false }
      after { Sufia.config.enable_noids = true }

      it "does not use the noid service" do
        expect_any_instance_of(ActiveFedora::Noid::Service).not_to receive(:mint)
        subject.assign_id
      end
    end
  end


  describe 'with a parent work' do
    let(:parent_id) { 'id123' }
    let!(:parent) {
      # if ActiveFedora::Base.exists?(parent_id)
      #   ActiveFedora::Base.eradicate(parent_id)
      # end
      GenericWork.new id: parent_id, title: ['asdf']
    }

    subject { CurationConcerns::GenericFile.create(batch: parent) }

    describe '#related_files' do
      let(:sibling) {
        sibling = CurationConcerns::GenericFile.create(batch: parent)
        sibling.apply_depositor_metadata(user)
        sibling
      }
      before do
        sibling.save!
      end

      it "has a related file in a batch" do
        expect(subject.related_files).to eq([sibling])
      end
    end

    describe '#processing?' do
      it "is not currently being processed by a batch" do
        expect(subject.processing?).to eq false
      end
    end

    describe '#remove_representative_relationship' do
      let(:some_other_id) { 'something456' }
      before do
        parent.representative = some_other_id
        parent.save!
      end

      context "the parent object doesn't exist" do
        before do
          parent.representative = subject.id
          parent.save!
          @parent_id = parent.id
          parent.destroy
        end

        it "doesn't raise an error" do
          expect(ActiveFedora::Base.exists?(@parent_id)).to eq false
          expect {
            subject.remove_representative_relationship
          }.to_not raise_error
        end
      end

      context 'it is not the representative' do
        it "doesn't update parent work when file is deleted" do
          expect(subject.batch).to eq parent
          expect(parent.representative).to eq some_other_id
          subject.destroy
          expect(parent.representative).to eq some_other_id
        end
      end

      context 'it is the representative' do
        before do
          parent.representative = subject.id
          parent.save!
        end

        it 'updates the parent work when the file is deleted' do
          expect(subject.batch).to eq parent
          expect(parent.representative).to eq subject.id
          subject.destroy
          expect(parent.representative).to be_nil
        end
      end
    end
  end

  describe "mime type recognition" do
    context "#image?" do
      context "when image/jp2" do
        before { subject.mime_type = 'image/jp2' }
        it { should be_image }
      end
      context "when image/jpg" do
        before { subject.mime_type = 'image/jpg' }
        it { should be_image }
      end
      context "when image/png" do
        before { subject.mime_type = 'image/png' }
        it { should be_image }
      end
      context "when image/tiff" do
        before { subject.mime_type = 'image/tiff' }
        it { should be_image }
      end
    end

    describe "#pdf?" do
      before { subject.mime_type = 'application/pdf' }
      it { should be_pdf }
    end

    describe "#audio?" do
      context "when x-wave" do
        before { subject.mime_type = 'audio/x-wave' }
        it { should be_audio }
      end
      context "when x-wav" do
        before { subject.mime_type = 'audio/x-wav' }
        it { should be_audio }
      end
      context "when mpeg" do
        before { subject.mime_type = 'audio/mpeg' }
        it { should be_audio }
      end
      context "when mp3" do
        before { subject.mime_type = 'audio/mp3' }
        it { should be_audio }
      end
      context "when ogg" do
        before { subject.mime_type = 'audio/ogg' }
        it { should be_audio }
      end
    end

    describe "#video?" do
      context "should be true for avi" do
        before { subject.mime_type = 'video/avi' }
        it { should be_video }
      end

      context "should be true for webm" do
        before { subject.mime_type = 'video/webm' }
        it { should be_video }
      end
      context "should be true for mp4" do
        before { subject.mime_type = 'video/mp4' }
        it { should be_video }
      end
      context "should be true for mpeg" do
        before { subject.mime_type = 'video/mpeg' }
        it { should be_video }
      end
      context "should be true for quicktime" do
        before { subject.mime_type = 'video/quicktime' }
        it { should be_video }
      end
      context "should be true for mxf" do
        before { subject.mime_type = 'application/mxf' }
        it { should be_video }
      end
    end
  end

end
