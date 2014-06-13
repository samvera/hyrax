require 'spec_helper'

describe GenericFile do

  subject { GenericFile.new }

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
        subject.should be_pdf
      end
    end
    context "when audio?" do
      it "should be true for wav" do
        subject.mime_type = 'audio/x-wave'
        subject.should be_audio
        subject.mime_type = 'audio/x-wav'
        subject.should be_audio
      end
      it "should be true for mpeg" do
        subject.mime_type = 'audio/mpeg'
        subject.should be_audio
        subject.mime_type = 'audio/mp3'
        subject.should be_audio
      end
      it "should be true for ogg" do
        subject.mime_type = 'audio/ogg'
        subject.should be_audio
      end
    end
    context "when video?" do
      it "should be true for avi" do
        subject.mime_type = 'video/avi'
        subject.should be_video
      end
      it "should be true for webm" do
        subject.mime_type = 'video/webm'
        subject.should be_video
      end
      it "should be true for mpeg" do
        subject.mime_type = 'video/mp4'
        subject.should be_video
        subject.mime_type = 'video/mpeg'
        subject.should be_video
      end
      it "should be true for quicktime" do
        subject.mime_type = 'video/quicktime'
        subject.should be_video
      end
      it "should be true for mxf" do
        subject.mime_type = 'application/mxf'
        subject.should be_video
      end
    end
  end

  describe "visibility" do
    it "should not be changed when it's new" do
      subject.should_not be_visibility_changed
    end
    it "should be changed when it has been changed" do
      subject.visibility= 'open'
      subject.should be_visibility_changed
    end

    it "should not be changed when it's set to its previous value" do
      subject.visibility= 'restricted'
      subject.should_not be_visibility_changed
    end

  end

  describe "attributes" do
    it "should have rightsMetadata" do
      subject.rightsMetadata.should be_instance_of ParanoidRightsDatastream
    end
    it "should have properties datastream for depositor" do
      subject.properties.should be_instance_of PropertiesDatastream
    end
    it "should have apply_depositor_metadata" do
      subject.rightsMetadata.edit_access.should == ['jcoyne']
      subject.depositor.should == 'jcoyne'
    end
    it "should have a set of permissions" do
      subject.read_groups=['group1', 'group2']
      subject.edit_users=['user1']
      subject.read_users=['user2', 'user3']
      subject.permissions.should == [{type: "group", access: "read", name: "group1"},
          {type: "group", access: "read", name: "group2"},
          {type: "user", access: "read", name: "user2"},
          {type: "user", access: "read", name: "user3"},
          {type: "user", access: "edit", name: "user1"}]
    end
    describe "updating permissions" do
      it "should create new group permissions" do
        subject.permissions = {new_group_name: {'group1'=>'read'}}
        subject.permissions.should == [{type: "group", access: "read", name: "group1"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
      it "should create new user permissions" do
        subject.permissions = {new_user_name: {'user1'=>'read'}}
        subject.permissions.should == [{type: "user", access: "read", name: "user1"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
      it "should not replace existing groups" do
        subject.permissions = {new_group_name: {'group1' => 'read'}}
        subject.permissions = {new_group_name: {'group2' => 'read'}}
        subject.permissions.should == [{type: "group", access: "read", name: "group1"},
                                     {type: "group", access: "read", name: "group2"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
      it "should not replace existing users" do
        subject.permissions = {new_user_name:{'user1'=>'read'}}
        subject.permissions = {new_user_name:{'user2'=>'read'}}
        subject.permissions.should == [{type: "user", access: "read", name: "user1"},
                                     {type: "user", access: "read", name: "user2"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
      it "should update permissions on existing users" do
        subject.permissions = {new_user_name:{'user1'=>'read'}}
        subject.permissions = {user:{'user1'=>'edit'}}
        subject.permissions.should == [{type: "user", access: "edit", name: "user1"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
      it "should update permissions on existing groups" do
        subject.permissions = {new_group_name:{'group1'=>'read'}}
        subject.permissions = {group:{'group1'=>'edit'}}
        subject.permissions.should == [{type: "group", access: "edit", name: "group1"},
                                     {type: "user", access: "edit", name: "jcoyne"}]
      end
    end
    it "should have a characterization datastream" do
      subject.characterization.should be_kind_of FitsDatastream
    end
    it "should have a dc desc metadata" do
      subject.descMetadata.should be_kind_of GenericFileRdfDatastream
    end
    it "should have content datastream" do
      subject.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      subject.content.should be_kind_of FileContentDatastream
    end
  end
  describe "delegations" do
    it "should delegate methods to properties metadata" do
      subject.should respond_to(:relative_path)
      subject.should respond_to(:depositor)
    end
    it "should delegate methods to descriptive metadata" do
      subject.should respond_to(:related_url)
      subject.should respond_to(:based_near)
      subject.should respond_to(:part_of)
      subject.should respond_to(:contributor)
      subject.should respond_to(:creator)
      subject.should respond_to(:title)
      subject.should respond_to(:description)
      subject.should respond_to(:publisher)
      subject.should respond_to(:date_created)
      subject.should respond_to(:date_uploaded)
      subject.should respond_to(:date_modified)
      subject.should respond_to(:subject)
      subject.should respond_to(:language)
      subject.should respond_to(:rights)
      subject.should respond_to(:resource_type)
      subject.should respond_to(:identifier)
    end
    it "should delegate methods to characterization metadata" do
      subject.should respond_to(:format_label)
      subject.should respond_to(:mime_type)
      subject.should respond_to(:file_size)
      subject.should respond_to(:last_modified)
      subject.should respond_to(:filename)
      subject.should respond_to(:original_checksum)
      subject.should respond_to(:well_formed)
      subject.should respond_to(:file_title)
      subject.should respond_to(:file_author)
      subject.should respond_to(:page_count)
    end
    it "should redefine to_param to make redis keys more recognizable" do
      subject.to_param.should == subject.noid
    end
    describe "that have been saved" do
      # This file has no content, so it doesn't characterize
      # before(:each) do
      #   Sufia.queue.should_receive(:push).once
      # end
      after(:each) do
        unless subject.inner_object.class == ActiveFedora::UnsavedDigitalObject
          begin
            subject.delete
          rescue ActiveFedora::ObjectNotFoundError
            # do nothing
          end
        end
      end
      it "should have activity stream-related methods defined" do
        subject.save
        f = subject.reload
        f.should respond_to(:stream)
        f.should respond_to(:events)
        f.should respond_to(:create_event)
        f.should respond_to(:log_event)
      end
      it "should be able to set values via delegated methods" do
        subject.related_url = "http://example.org/"
        subject.creator = "John Doe"
        subject.title = "New work"
        subject.save
        f = subject.reload
        f.related_url.should == ["http://example.org/"]
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
      end
      it "should be able to be added to w/o unexpected graph behavior" do
        subject.creator = "John Doe"
        subject.title = "New work"
        subject.save
        f = subject.reload
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
        f.creator = "Jane Doe"
        f.title << "Newer work"
        f.save
        f = subject.reload
        f.creator.should == ["Jane Doe"]
        f.title.should == ["New work", "Newer work"]
      end
    end
  end
  describe "to_solr" do
    before do
      allow(subject).to receive(:pid).and_return('stubbed_pid')
      subject.part_of = "Arabiana"
      subject.contributor = "Mohammad"
      subject.creator = "Allah"
      subject.title = "The Work"
      subject.description = "The work by Allah"
      subject.publisher = "Vertigo Comics"
      subject.date_created = "1200-01-01"
      subject.date_uploaded = Date.parse("2011-01-01")
      subject.date_modified = Date.parse("2012-01-01")
      subject.subject = "Theology"
      subject.language = "Arabic"
      subject.rights = "Wide open, buddy."
      subject.resource_type = "Book"
      subject.identifier = "urn:isbn:1234567890"
      subject.based_near = "Medina, Saudi Arabia"
      subject.related_url = "http://example.org/TheWork/"
      subject.mime_type = "image/jpeg"
      subject.format_label = "JPEG Image"
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
    end
  end
  it "should support multi-valued fields in solr" do
    subject.tag = ["tag1", "tag2"]
    lambda { subject.save }.should_not raise_error
    subject.delete
  end
  it "should support setting and getting the relative_path value" do
    subject.relative_path = "documents/research/NSF/2010"
    subject.relative_path.should == "documents/research/NSF/2010"
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
        @f.stub(mime_type: 'video/quicktime')  #Would get set by the characterization job
        @f.add_file(File.open("#{fixture_path}/countdown.avi", 'rb'), 'content', 'countdown.avi')
        @f.save
      end
      it "should make a png thumbnail" do
        @f.create_thumbnail
        @f.thumbnail.content.size.should == 4768 # this is a bad test. I just want to show that it did something.
        @f.thumbnail.mimeType.should == 'image/png'
      end
    end
  end
  describe "trophies" do
    before do
      u = FactoryGirl.create(:jill)
      @f = GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(u)
        gf.save!
      end
      @t = Trophy.create(user_id: u.id, generic_file_id: @f.pid)
    end
    it "should have a trophy" do
      Trophy.where(generic_file_id: @f.pid).count.should == 1
    end
    it "should remove all trophies when file is deleted" do
      @f.should_receive(:cleanup_trophies)
      @f.destroy
      Trophy.where(generic_file_id: @f.pid).count.should == 0
    end
  end

  describe "audit" do
    before do
      u = FactoryGirl.create(:jill)
      f = GenericFile.new
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata(u)
      f.save!
      @f = f.reload
    end
    it "should schedule a audit job for each datastream" do
      s0 = double('zero')
      AuditJob.should_receive(:new).with(@f.pid, 'descMetadata', "descMetadata.0").and_return(s0)
      Sufia.queue.should_receive(:push).with(s0)
      s1 = double('one')
      AuditJob.should_receive(:new).with(@f.pid, 'DC', "DC1.0").and_return(s1)
      Sufia.queue.should_receive(:push).with(s1)
      s2 = double('two')
      AuditJob.should_receive(:new).with(@f.pid, 'RELS-EXT', "RELS-EXT.0").and_return(s2)
      Sufia.queue.should_receive(:push).with(s2)
      s3 = double('three')
      AuditJob.should_receive(:new).with(@f.pid, 'rightsMetadata', "rightsMetadata.0").and_return(s3)
      Sufia.queue.should_receive(:push).with(s3)
      s4 = double('four')
      AuditJob.should_receive(:new).with(@f.pid, 'properties', "properties.0").and_return(s4)
      Sufia.queue.should_receive(:push).with(s4)
      s5 = double('five')
      AuditJob.should_receive(:new).with(@f.pid, 'content', "content.0").and_return(s5)
      Sufia.queue.should_receive(:push).with(s5)
      @f.audit!
    end
    it "should log a failing audit" do
      @f.datastreams.each { |ds| ds.stub(:dsChecksumValid).and_return(false) }
      GenericFile.stub(:run_audit).and_return(double(:respose, pass:1, created_at: '2005-12-20', pid: 'foo:123', dsid: 'foo', version: '1'))
      @f.audit!
      expect(ChecksumAuditLog.all).to be_all { |cal| cal.pass == 0 }
    end
    it "should log a passing audit" do
      GenericFile.stub(:run_audit).and_return(double(:respose, pass:1, created_at: '2005-12-20', pid: 'foo:123', dsid: 'foo', version: '1'))
      @f.audit!
      expect(ChecksumAuditLog.all).to be_all { |cal| cal.pass == 1 }
    end

    it "should return true on audit_status" do
      expect(@f.audit_stat).to be_truthy
    end
  end

  describe "run_audit" do
    before do
      @f = GenericFile.new
      @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @f.apply_depositor_metadata('mjg36')
      @f.save!
      @version = @f.datastreams['content'].versions.first
      @old = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 1, created_at: 2.minutes.ago)
      @new = ChecksumAuditLog.create(pid: @f.pid, dsid: @version.dsid, version: @version.versionID, pass: 0)
    end
    it "should not prune failed audits" do
      @version.should_receive(:dsChecksumValid).and_return(true)
      GenericFile.run_audit(@version)

      @version.should_receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      @version.should_receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      @version.should_receive(:dsChecksumValid).and_return(true)
      GenericFile.run_audit(@version)

      @version.should_receive(:dsChecksumValid).and_return(false)
      GenericFile.run_audit(@version)

      @f.logs(@version.dsid).map(&:pass).should == [0, 1, 0, 0, 1, 0, 1]
    end

  end

  describe "related_files" do
    let(:batch_id) { "foobar:100" }
    before(:each) do
      @f1 = GenericFile.new
      @f2 = GenericFile.new
      @f3 = GenericFile.new
      @f1.apply_depositor_metadata('mjg36')
      @f2.apply_depositor_metadata('mjg36')
      @f3.apply_depositor_metadata('mjg36')
    end

    describe "when the files belong to a batch" do
      after(:each) do
        @f1.delete
        @f2.delete
        @f3.delete
      end
      before do
        @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
        @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
        @f3.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
        @f1.save!
        @f2.save!
        @f3.save!
      end
      it "should never return a file in its own related_files method" do
        @f1.related_files.should match_array [@f2, @f3]
        @f2.related_files.should match_array [@f1, @f3]
        @f3.related_files.should match_array [@f1, @f2]
      end
    end
    it "should return an empty array when there are no related files" do
      @f1.related_files.should == []
    end
  end
  describe "noid integration" do
    before(:all) do
      @new_file = GenericFile.new(pid: 'ns:123')
      @new_file.apply_depositor_metadata('mjg36')
      @new_file.save
    end
    after(:all) do
      @new_file.delete
    end
    it "should support the noid method" do
      @new_file.should respond_to(:noid)
    end
    it "should return the expected identifier" do
      @new_file.noid.should == '123'
    end
    it "should work outside of an instance" do
      new_id = Sufia::IdService.mint
      noid = new_id.split(':').last
      Sufia::Noid.noidify(new_id).should == noid
    end
  end
  describe "characterize" do
    it "should return expected results when called", unless: $in_travis do
      subject.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      subject.characterize
      doc = Nokogiri::XML.parse(subject.characterization.content)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    context "after characterization" do
      before(:all) do
        myfile = GenericFile.new
        myfile.add_file(File.open(fixture_path + '/sufia/sufia_test4.pdf', 'rb').read, 'content', 'sufia_test4.pdf')
        myfile.label = 'label123'
        myfile.apply_depositor_metadata('mjg36')
        myfile.characterize
        myfile.save
        @myfile = myfile.reload
      end
      after(:all) do
        @myfile.delete
      end
      it "should return expected results after a save" do
        @myfile.file_size.should == ['218882']
        @myfile.original_checksum.should == ['5a2d761cab7c15b2b3bb3465ce64586d']
      end
      it "should return a hash of all populated values from the characterization terminology" do
        @myfile.characterization_terms[:format_label].should == ["Portable Document Format"]
        @myfile.characterization_terms[:mime_type].should == "application/pdf"
        @myfile.characterization_terms[:file_size].should == ["218882"]
        @myfile.characterization_terms[:original_checksum].should == ["5a2d761cab7c15b2b3bb3465ce64586d"]
        @myfile.characterization_terms.keys.should include(:last_modified)
        @myfile.characterization_terms.keys.should include(:filename)
      end
      it "should append metadata from the characterization" do
        @myfile.title.should include("Microsoft Word - sample.pdf.docx")
        @myfile.filename[0].should == @myfile.label
      end

      it "should append each term only once" do
        @myfile.append_metadata
        @myfile.format_label.should == ["Portable Document Format"]
        @myfile.title.should include("Microsoft Word - sample.pdf.docx")
      end
    end
  end
  describe "label" do
    it "should set the inner label" do
      subject.label = "My New Label"
      subject.inner_object.label.should == "My New Label"
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
      subject.read_groups.should == ['group-6', 'group-7']
    end
    it "should have read groups string accessor" do
      subject.read_groups_string.should == 'group-6, group-7'
    end
    it "should have read groups writer" do
      subject.read_groups = ['group-2', 'group-3']
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.users.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      subject.rightsMetadata.groups.should == {'umg/up.dlt.staff' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.users.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.users.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
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
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(read_users_string: 'mjg36') }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :person] => '')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({person: "mjg36"}, "read")
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"person" => {"mjg36" => "read"}})
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :person] => '')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
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
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(edit_groups_string: 'public') }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'public')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "public"}, "edit")
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"public" => "edit"}})
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'public')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
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
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(edit_groups_string: 'registered') }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "registered"}, "edit")
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "edit"}})
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        expect(@file).to_not be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        expect(@file).to be_new_record
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
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
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(read_groups_string: 'registered') }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:read_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via permissions()" do
        @rightsmd.permissions({group: "registered"}, "read")
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "read"}})
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
        expect(@file).to be_valid
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:read_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        expect(@file).to_not be_new_record
        @file.errors.should be_empty
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
        subject.should_not be_persisted
        expect(subject.errors.messages).to eq(base: ["A virus was found in #{f.path}: EL CRAPO VIRUS"])
      end
      it "does not save a new version of a GenericFile" do
        subject.add_file(f, 'content', 'small_file.txt')
        subject.save
        allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError)
        subject.add_file(File.new(fixture_path + '/sufia_generic_stub.txt') , 'content', 'sufia_generic_stub.txt')
        subject.save
        subject.reload.content.content.should == "small\n"
      end
    end
  end

  describe "should create a full to_solr record" do
    before do
      subject.save
    end
    after do
      subject.destroy
    end
    it "gets both sets of data into solr" do
     f1= GenericFile.find(subject.id)
     f2 = GenericFile.find(subject.id)
     f2.reload_on_save = true
     f1.mime_type = "video/abc123"
     f2.title = "abc123"
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
      it { should be_public }
    end

    context "when read group is not set to public" do
      before { subject.read_groups = ['foo'] }
      it { should_not be_public }
    end
  end
end
