require 'spec_helper'

describe GenericFile, :type => :model do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  before(:each) do
    @file = GenericFile.new
    @file.apply_depositor_metadata(user.user_key)
  end

  describe "created for someone (proxy)" do
    before do
      @transfer_to = FactoryGirl.find_or_create(:jill)
    end
    after do
      @file.destroy
    end

    it "transfers the request" do
      @file.on_behalf_of = @transfer_to.user_key
      stub_job = double('change depositor job')
      allow(ContentDepositorChangeEventJob).to receive(:new).and_return(stub_job)
      expect(Sufia.queue).to receive(:push).with(stub_job).once.and_return(true)
      @file.save!
    end
  end

  describe "delegations" do
    before do
      @file.proxy_depositor = "sally@example.com"
    end
    it "should include proxies" do
      expect(@file).to respond_to(:relative_path)
      expect(@file).to respond_to(:depositor)
      expect(@file.proxy_depositor).to eq 'sally@example.com'
    end
  end

  before do
    subject.apply_depositor_metadata('jcoyne')
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

  describe "assign_pid" do
    it "should use the noid id service" do
      expect(Sufia::IdService).to receive(:mint)
      GenericFile.assign_pid(nil)
    end
  end

  describe "mime type recognition" do
    context "when image?" do
      it "should be true for jpeg2000" do
        subject.mime_type = 'image/jp2'
        expect(subject).to be_image
      end
      it "should be true for jpeg" do
        subject.mime_type = 'image/jpg'
        expect(subject).to be_image
      end
      it "should be true for png" do
        subject.mime_type = 'image/png'
        expect(subject).to be_image
      end
      it "should be true for tiff" do
        subject.mime_type = 'image/tiff'
        expect(subject).to be_image
      end
    end
    context "when pdf?" do
      it "should be true for pdf" do
        subject.mime_type = 'application/pdf'
        expect(subject).to be_pdf
      end
    end
    context "when audio?" do
      it "should be true for wav" do
        subject.mime_type = 'audio/x-wave'
        expect(subject).to be_audio
        subject.mime_type = 'audio/x-wav'
        expect(subject).to be_audio
      end
      it "should be true for mpeg" do
        subject.mime_type = 'audio/mpeg'
        expect(subject).to be_audio
        subject.mime_type = 'audio/mp3'
        expect(subject).to be_audio
      end
      it "should be true for ogg" do
        subject.mime_type = 'audio/ogg'
        expect(subject).to be_audio
      end
    end
    context "when video?" do
      it "should be true for avi" do
        subject.mime_type = 'video/avi'
        expect(subject).to be_video
      end
      it "should be true for webm" do
        subject.mime_type = 'video/webm'
        expect(subject).to be_video
      end
      it "should be true for mpeg" do
        subject.mime_type = 'video/mp4'
        expect(subject).to be_video
        subject.mime_type = 'video/mpeg'
        expect(subject).to be_video
      end
      it "should be true for quicktime" do
        subject.mime_type = 'video/quicktime'
        expect(subject).to be_video
      end
      it "should be true for mxf" do
        subject.mime_type = 'application/mxf'
        expect(subject).to be_video
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

  describe "attributes" do
    it "should have rightsMetadata" do
      expect(subject.rightsMetadata).to be_instance_of ParanoidRightsDatastream
    end
    it "should have properties datastream for depositor" do
      expect(subject.properties).to be_instance_of PropertiesDatastream
    end
    it "should have apply_depositor_metadata" do
      expect(subject.rightsMetadata.edit_access).to eq(['jcoyne'])
      expect(subject.depositor).to eq('jcoyne')
    end
    it "should have a set of permissions" do
      subject.read_groups=['group1', 'group2']
      subject.edit_users=['user1']
      subject.read_users=['user2', 'user3']
      expect(subject.permissions).to eq([{type: "group", access: "read", name: "group1"},
          {type: "group", access: "read", name: "group2"},
          {type: "user", access: "read", name: "user2"},
          {type: "user", access: "read", name: "user3"},
          {type: "user", access: "edit", name: "user1"}])
    end
    describe "updating permissions" do
      it "should create new group permissions" do
        subject.permissions = {new_group_name: {'group1'=>'read'}}
        expect(subject.permissions).to eq([{type: "group", access: "read", name: "group1"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
      it "should create new user permissions" do
        subject.permissions = {new_user_name: {'user1'=>'read'}}
        expect(subject.permissions).to eq([{type: "user", access: "read", name: "user1"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
      it "should not replace existing groups" do
        subject.permissions = {new_group_name: {'group1' => 'read'}}
        subject.permissions = {new_group_name: {'group2' => 'read'}}
        expect(subject.permissions).to eq([{type: "group", access: "read", name: "group1"},
                                     {type: "group", access: "read", name: "group2"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
      it "should not replace existing users" do
        subject.permissions = {new_user_name:{'user1'=>'read'}}
        subject.permissions = {new_user_name:{'user2'=>'read'}}
        expect(subject.permissions).to eq([{type: "user", access: "read", name: "user1"},
                                     {type: "user", access: "read", name: "user2"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
      it "should update permissions on existing users" do
        subject.permissions = {new_user_name:{'user1'=>'read'}}
        subject.permissions = {user:{'user1'=>'edit'}}
        expect(subject.permissions).to eq([{type: "user", access: "edit", name: "user1"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
      it "should update permissions on existing groups" do
        subject.permissions = {new_group_name:{'group1'=>'read'}}
        subject.permissions = {group:{'group1'=>'edit'}}
        expect(subject.permissions).to eq([{type: "group", access: "edit", name: "group1"},
                                     {type: "user", access: "edit", name: "jcoyne"}])
      end
    end
    it "should have a characterization datastream" do
      expect(subject.characterization).to be_kind_of FitsDatastream
    end
    it "should have a dc desc metadata" do
      expect(subject.descMetadata).to be_kind_of GenericFileRdfDatastream
    end
    it "should have content datastream" do
      subject.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      expect(subject.content).to be_kind_of FileContentDatastream
    end
  end
  describe "delegations" do
    it "should delegate methods to properties metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
    end
    it "should delegate methods to descriptive metadata" do
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
      expect(subject.to_param).to eq(subject.noid)
    end

    describe "that have been saved" do
      after do
        subject.delete unless subject.new_record?
      end

      it "should have activity stream-related methods defined" do
        subject.save
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
        expect(f.related_url).to eq(["http://example.org/"])
        expect(f.creator).to eq(["John Doe"])
        expect(f.title).to eq(["New work"])
      end

      it "should be able to be added to w/o unexpected graph behavior" do
        subject.creator = ["John Doe"]
        subject.title = ["New work"]
        subject.save
        f = subject.reload
        expect(f.creator).to eq(["John Doe"])
        expect(f.title).to eq(["New work"])
        f.creator = ["Jane Doe"]
        f.title << "Newer work"
        f.save
        f = subject.reload
        expect(f.creator).to eq(["Jane Doe"])
        expect(f.title).to eq(["New work", "Newer work"])
      end
    end
  end

  describe "to_solr" do
    before do
      allow(subject).to receive(:id).and_return('stubbed_pid')
      subject.part_of = ["Arabiana"]
      subject.contributor = ["Mohammad"]
      subject.creator = ["Allah"]
      subject.title = ["The Work"]
      subject.description = ["The work by Allah"]
      subject.publisher = ["Vertigo Comics"]
      subject.date_created = ["1200-01-01"]
      subject.date_uploaded = Date.parse("2011-01-01")
      subject.date_modified = Date.parse("2012-01-01")
      subject.subject = ["Theology"]
      subject.language = ["Arabic"]
      subject.rights = ["Wide open, buddy."]
      subject.resource_type = ["Book"]
      subject.identifier = ["urn:isbn:1234567890"]
      subject.based_near = ["Medina, Saudi Arabia"]
      subject.related_url = ["http://example.org/TheWork/"]
      subject.mime_type = "image/jpeg"
      subject.format_label = ["JPEG Image"]
      subject.full_text.content = 'abcxyz'
    end

    it "supports to_solr" do
      local = subject.to_solr
      expect(local[Solrizer.solr_name("desc_metadata__part_of")]).to be_nil
      expect(local[Solrizer.solr_name("desc_metadata__date_uploaded")]).to be_nil
      expect(local[Solrizer.solr_name("desc_metadata__date_modified")]).to be_nil
      expect(local[Solrizer.solr_name("desc_metadata__date_uploaded", :stored_sortable, type: :date)]).to eq '2011-01-01T00:00:00Z'
      expect(local[Solrizer.solr_name("desc_metadata__date_modified", :stored_sortable, type: :date)]).to eq '2012-01-01T00:00:00Z'
      expect(local[Solrizer.solr_name("desc_metadata__rights")]).to eq ["Wide open, buddy."]
      expect(local[Solrizer.solr_name("desc_metadata__related_url")]).to eq ["http://example.org/TheWork/"]
      expect(local[Solrizer.solr_name("desc_metadata__contributor")]).to eq ["Mohammad"]
      expect(local[Solrizer.solr_name("desc_metadata__creator")]).to eq ["Allah"]
      expect(local[Solrizer.solr_name("desc_metadata__title")]).to eq ["The Work"]
      expect(local["desc_metadata__title_sim"]).to eq ["The Work"]
      expect(local[Solrizer.solr_name("desc_metadata__description")]).to eq ["The work by Allah"]
      expect(local[Solrizer.solr_name("desc_metadata__publisher")]).to eq ["Vertigo Comics"]
      expect(local[Solrizer.solr_name("desc_metadata__subject")]).to eq ["Theology"]
      expect(local[Solrizer.solr_name("desc_metadata__language")]).to eq ["Arabic"]
      expect(local[Solrizer.solr_name("desc_metadata__date_created")]).to eq ["1200-01-01"]
      expect(local[Solrizer.solr_name("desc_metadata__resource_type")]).to eq ["Book"]
      expect(local[Solrizer.solr_name("file_format")]).to eq "jpeg (JPEG Image)"
      expect(local[Solrizer.solr_name("desc_metadata__identifier")]).to eq ["urn:isbn:1234567890"]
      expect(local[Solrizer.solr_name("desc_metadata__based_near")]).to eq ["Medina, Saudi Arabia"]
      expect(local[Solrizer.solr_name("mime_type")]).to eq ["image/jpeg"]
      expect(local["noid_tsi"]).to eq 'stubbed_pid'
      expect(local['all_text_timv']).to eq('abcxyz')
    end
  end
  it "should support multi-valued fields in solr" do
    subject.tag = ["tag1", "tag2"]
    expect { subject.save }.not_to raise_error
    subject.delete
  end
  it "should support setting and getting the relative_path value" do
    subject.relative_path = "documents/research/NSF/2010"
    expect(subject.relative_path).to eq("documents/research/NSF/2010")
  end
  describe "create_thumbnail" do
    before do
      @f = GenericFile.new
      @f.apply_depositor_metadata('mjg36')
    end
    after do
      @f.delete
    end
    describe "with a video", if: Sufia.config.enable_ffmpeg do
      before do
        allow(@f).to receive_messages(mime_type: 'video/quicktime')  #Would get set by the characterization job
        @f.add_file(File.open("#{fixture_path}/countdown.avi", 'rb'), 'content', 'countdown.avi')
        @f.save
      end
      it "should make a png thumbnail" do
        @f.create_thumbnail
        expect(@f.thumbnail.content.size).to eq(4768) # this is a bad test. I just want to show that it did something.
        expect(@f.thumbnail.mime_type).to eq('image/png')
      end
    end
  end
  describe "trophies" do
    before do
      u = FactoryGirl.find_or_create(:jill)
      @f = GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(u)
        gf.save!
      end
      @t = Trophy.create(user_id: u.id, generic_file_id: @f.noid)
    end
    it "should have a trophy" do
      expect(Trophy.where(generic_file_id: @f.noid).count).to eq 1
    end
    it "should remove all trophies when file is deleted" do
      @f.destroy
      expect(Trophy.where(generic_file_id: @f.noid).count).to eq 0
    end
  end

  describe "audit" do
    before do
      u = FactoryGirl.find_or_create(:jill)
      f = GenericFile.new
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata(u)
      f.save!
      @f = f.reload
    end
    it "should schedule a audit job for each datastream" do
      skip "Disabled audit"
      s0 = double('zero')
      expect(AuditJob).to receive(:new).with(@f.pid, 'descMetadata', "descMetadata.0").and_return(s0)
      expect(Sufia.queue).to receive(:push).with(s0)
      s1 = double('one')
      expect(AuditJob).to receive(:new).with(@f.pid, 'DC', "DC1.0").and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1)
      s2 = double('two')
      expect(AuditJob).to receive(:new).with(@f.pid, 'RELS-EXT', "RELS-EXT.0").and_return(s2)
      expect(Sufia.queue).to receive(:push).with(s2)
      s3 = double('three')
      expect(AuditJob).to receive(:new).with(@f.pid, 'rightsMetadata', "rightsMetadata.0").and_return(s3)
      expect(Sufia.queue).to receive(:push).with(s3)
      s4 = double('four')
      expect(AuditJob).to receive(:new).with(@f.pid, 'properties', "properties.0").and_return(s4)
      expect(Sufia.queue).to receive(:push).with(s4)
      s5 = double('five')
      expect(AuditJob).to receive(:new).with(@f.pid, 'content', "content.0").and_return(s5)
      expect(Sufia.queue).to receive(:push).with(s5)
      @f.audit!
    end
    it "should log a failing audit" do
      @f.datastreams.each { |ds| allow(ds).to receive(:dsChecksumValid).and_return(false) }
      allow(GenericFile).to receive(:run_audit).and_return(double(:respose, pass:1, created_at: '2005-12-20', pid: 'foo:123', dsid: 'foo', version: '1'))
      @f.audit!
      expect(ChecksumAuditLog.all).to be_all { |cal| cal.pass == 0 }
    end
    it "should log a passing audit" do
      allow(GenericFile).to receive(:run_audit).and_return(double(:respose, pass:1, created_at: '2005-12-20', pid: 'foo:123', dsid: 'foo', version: '1'))
      @f.audit!
      expect(ChecksumAuditLog.all).to be_all { |cal| cal.pass == 1 }
    end

    it "should return true on audit_status" do
      skip "Disabled audit"
      expect(@f.audit_stat).to be_truthy
    end
  end

  describe "run_audit" do
    before do
      skip "disabled audit"
      @f = GenericFile.new
      @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @f.apply_depositor_metadata('mjg36')
      @f.save!
      @version = @f.datastreams['content'].versions.first
      @old = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 1, created_at: 2.minutes.ago)
      @new = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 0)
    end
    it "should not prune failed audits" do
      expect(@version).to receive(:dsChecksumValid).and_return(true)
      GenericFile.run_audit(@version)

      expect(@version).to receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      expect(@version).to receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      expect(@version).to receive(:dsChecksumValid).and_return(true)
      GenericFile.run_audit(@version)

      expect(@version).to receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      expect(@f.logs(@version.dsid).map(&:pass)).to eq([0, 1, 0, 0, 1, 0, 1])
    end

  end

  describe "#related_files" do
    let!(:f1) do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end
    let!(:f2) do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end
    let!(:f3) do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.batch_id = batch_id
        f.save
      end
    end

    context "when the files belong to a batch" do
      let(:batch) { Batch.create }
      let(:batch_id) { batch.id }

      it "shouldn't return itself from the related_files method" do
        expect(f1.related_files).to match_array [f2, f3]
        expect(f2.related_files).to match_array [f1, f3]
        expect(f3.related_files).to match_array [f1, f2]
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
    subject { GenericFile.new('ns-123') }

    it "should return the expected identifier" do
      expect(subject.noid).to eq 'ns-123'
    end

    it "should work outside of an instance" do
      new_id = Sufia::IdService.mint
      expect(Sufia::Noid.noidify(new_id)).to eq new_id
    end
  end

  describe "characterize" do
    it "should return expected results when called", unless: $in_travis do
      subject.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      subject.characterize
      doc = Nokogiri::XML.parse(subject.characterization.content)
      expect(doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text).to eq('50')
    end
    context "after characterization" do
      before(:all) do
        myfile = GenericFile.new
        myfile.add_file(File.open(fixture_path + '/sufia/sufia_test4.pdf', 'rb').read, 'content', 'sufia_test4.pdf')
        myfile.label = 'label123'
        myfile.apply_depositor_metadata('mjg36')
        # characterize method saves
        myfile.characterize
        @myfile = myfile.reload
      end
      after(:all) do
        @myfile.destroy
      end
      it "should return expected results after a save" do
        expect(@myfile.file_size).to eq(['218882'])
        expect(@myfile.original_checksum).to eq(['5a2d761cab7c15b2b3bb3465ce64586d'])
      end
      it "should return a hash of all populated values from the characterization terminology" do
        expect(@myfile.characterization_terms[:format_label]).to eq(["Portable Document Format"])
        expect(@myfile.characterization_terms[:mime_type]).to eq("application/pdf")
        expect(@myfile.characterization_terms[:file_size]).to eq(["218882"])
        expect(@myfile.characterization_terms[:original_checksum]).to eq(["5a2d761cab7c15b2b3bb3465ce64586d"])
        expect(@myfile.characterization_terms.keys).to include(:last_modified)
        expect(@myfile.characterization_terms.keys).to include(:filename)
      end
      it "should append metadata from the characterization" do
        expect(@myfile.title).to include("Microsoft Word - sample.pdf.docx")
        expect(@myfile.filename[0]).to eq(@myfile.label)
      end
      it "should append each term only once" do
        @myfile.append_metadata
        expect(@myfile.format_label).to eq(["Portable Document Format"])
        expect(@myfile.title).to include("Microsoft Word - sample.pdf.docx")
      end
      it 'includes extracted full-text content' do
        expect(@myfile.full_text.content).to eq("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nMicrosoft Word - sample.pdf.docx\n\n\n \n \n\n \n\n \n\n \n\nThis PDF file was created using CutePDF. \n\nwww.cutepdf.com")
      end
    end
  end

  context "with rightsMetadata" do
    subject do
      m = GenericFile.new()
      m.rightsMetadata.update_permissions("person"=>{"person1"=>"read","person2"=>"read"}, "group"=>{'group-6' => 'read', "group-7"=>'read', 'group-8'=>'edit'})
      #m.save
      m
    end
    it "should have read groups accessor" do
      expect(subject.read_groups).to eq(['group-6', 'group-7'])
    end
    it "should have read groups string accessor" do
      expect(subject.read_groups_string).to eq('group-6, group-7')
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      expect(subject.rightsMetadata.groups).to eq({'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'})
      expect(subject.rightsMetadata.users).to eq({"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'})
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      expect(subject.rightsMetadata.groups).to eq({'umg/up.dlt.staff' => 'read', 'group-3'=>'read', 'group-8' => 'edit'})
      expect(subject.rightsMetadata.users).to eq({"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'})
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.rightsMetadata.groups).to eq({'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'})
      expect(subject.rightsMetadata.users).to eq({"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'})
    end
  end
  describe "permissions validation" do
    context "depositor must have edit access" do
      before(:each) do
        @file = GenericFile.new
        @file.apply_depositor_metadata('mjg36')
        @rightsmd = @file.rightsMetadata
      end
      before(:all) do
        @rights_xml = <<-RIGHTS
<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human></human>
    <machine></machine>
  </copyright>
  <access type="read">
    <human></human>
    <machine></machine>
  </access>
  <access type="read">
    <human></human>
    <machine>
      <person>mjg36</person>
    </machine>
  </access>
  <access type="edit">
    <human></human>
    <machine></machine>
  </access>
  <embargo>
    <human></human>
    <machine></machine>
  </embargo>
</rightsMetadata>
      RIGHTS
      end
      it "should work via permissions=()" do
        @file.permissions = {user: {'mjg36' => 'read'}}
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update" do
        # automatically triggers save
        expect { @file.update(read_users_string: 'mjg36') }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :person] => '')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({person: "mjg36"}, "read")
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"person" => {"mjg36" => "read"}})
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :person] => '')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_users)
        expect(@file.errors[:edit_users]).to include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
    end
    context "public must not have edit access" do
      before(:each) do
        @file = GenericFile.new
        @file.apply_depositor_metadata('mjg36')
        @file.read_groups = ['public']
        @rightsmd = @file.rightsMetadata
      end
      before(:all) do
        @rights_xml = <<-RIGHTS
<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human></human>
    <machine></machine>
  </copyright>
  <access type="read">
    <human></human>
    <machine></machine>
  </access>
  <access type="read">
    <human></human>
    <machine></machine>
  </access>
  <access type="edit">
    <human></human>
    <machine>
      <group>public</group>
    </machine>
  </access>
  <embargo>
    <human></human>
    <machine></machine>
  </embargo>
</rightsMetadata>
        RIGHTS
      end
      it "should work via permissions=()" do
        @file.permissions = {group: {'public' => 'edit'}}
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update" do
        # automatically triggers save
        expect { @file.update(edit_groups_string: 'public') }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'public')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "public"}, "edit")
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"public" => "edit"}})
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'public')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
    end
    context "registered must not have edit access" do
      before(:each) do
        @file = GenericFile.new
        @file.apply_depositor_metadata('mjg36')
        @file.read_groups = ['registered']
        @rightsmd = @file.rightsMetadata
      end
      before(:all) do
        @rights_xml = <<-RIGHTS
<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human></human>
    <machine></machine>
  </copyright>
  <access type="read">
    <human></human>
    <machine></machine>
  </access>
  <access type="read">
    <human></human>
    <machine></machine>
  </access>
  <access type="edit">
    <human></human>
    <machine>
      <group>registered</group>
    </machine>
  </access>
  <embargo>
    <human></human>
    <machine></machine>
  </embargo>
</rightsMetadata>
        RIGHTS
      end
      it "should work via permissions=()" do
        @file.permissions = {group: {'registered' => 'edit'}}
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update" do
        # automatically triggers save
        expect { @file.update(edit_groups_string: 'registered') }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'registered')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "registered"}, "edit")
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "edit"}})
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'registered')
        expect { @file.save }.not_to raise_error
        expect(@file).to be_new_record
        expect(@file.errors).to include(:edit_groups)
        expect(@file.errors[:edit_groups]).to include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
    end
    context "everything is copacetic" do
      before(:each) do
        @file = GenericFile.new
        @file.apply_depositor_metadata('mjg36')
        @file.read_groups = ['public']
        @rightsmd = @file.rightsMetadata
      end
      after(:each) do
        @file.delete
      end
      before(:all) do
        @rights_xml = <<-RIGHTS
<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human></human>
    <machine></machine>
  </copyright>
  <access type="read">
    <human></human>
    <machine>
      <group>public</group>
      <group>registered</group>
    </machine>
  </access>
  <access type="edit">
    <human></human>
    <machine>
      <person>mjg36</person>
    </machine>
  </access>
  <embargo>
    <human></human>
    <machine></machine>
  </embargo>
</rightsMetadata>
      RIGHTS
      end
      it "should work via permissions=()" do
        @file.permissions = {group: {'registered' => 'read'}}
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via update" do
        # automatically triggers save
        expect { @file.update(read_groups_string: 'registered') }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:read_access, :group] => 'registered')
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "registered"}, "read")
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "read"}})
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:read_access, :group] => 'registered')
        expect { @file.save }.not_to raise_error
        expect(@file).to_not be_new_record
        expect(@file.errors).to be_empty
        expect(@file).to be_valid
      end
    end
  end
  describe "file content validation" do
    context "when file contains a virus" do
      let(:f) { File.new(fixture_path + '/small_file.txt') }
      after(:each) do
        subject.destroy if subject.persisted?
      end
      it "populates the errors hash during validation" do
        allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError, "A virus was found in #{f.path}: EL CRAPO VIRUS")
        subject.add_file(f, 'content', 'small_file.txt')
        subject.save
        expect(subject).not_to be_persisted
        expect(subject.errors.messages).to eq(base: ["A virus was found in #{f.path}: EL CRAPO VIRUS"])
      end
      it "does not save a new version of a GenericFile" do
        subject.add_file(f, 'content', 'small_file.txt')
        subject.save
        allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError)
        subject.add_file(File.new(fixture_path + '/sufia_generic_stub.txt') , 'content', 'sufia_generic_stub.txt')
        subject.save
        expect(subject.reload.content.content).to eq("small\n")
      end
    end
  end

  describe "should create a full to_solr record" do
    subject do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata('jcoyne')
        f.save
      end
    end

    after do
      subject.destroy
    end

    it "gets both sets of data into solr" do
     f1= GenericFile.find(subject.id)
     f2 = GenericFile.find(subject.id)
     f2.reload_on_save = true
     f1.mime_type = "video/abc123"
     f2.title = ["abc123"]
     f1.save
     mime_type_key = Solrizer.solr_name("mime_type")
     title_key = Solrizer.solr_name("desc_metadata__title", :stored_searchable, type: :string)
     expect(f1.to_solr[mime_type_key]).to eq([f1.mime_type])
     expect(f1.to_solr[title_key]).to_not eq(f2.title)
     f2.save
     expect(f2.to_solr[mime_type_key]).to eq([f1.mime_type])
     expect(f2.to_solr[title_key]).to eq(f2.title)
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
end
