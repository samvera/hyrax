require 'spec_helper'

describe GenericFile do
  before do
    subject.apply_depositor_metadata('jcoyne')
    @file = subject #TODO remove this line someday (use subject instead)
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
    describe "image?" do
      it "should be true for jpeg2000" do
        subject.mime_type = 'image/jp2'
        subject.should be_image
      end
      it "should be true for jpeg" do
        subject.mime_type = 'image/jpg'
        subject.should be_image
      end
      it "should be true for png" do
        subject.mime_type = 'image/png'
        subject.should be_image
      end
    end
    describe "pdf?" do
      it "should be true for pdf" do
        subject.mime_type = 'application/pdf'
        subject.should be_pdf
      end
    end
    describe "audio?" do
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
    describe "video?" do
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
      subject.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
          {:type=>"group", :access=>"read", :name=>"group2"},
          {:type=>"user", :access=>"read", :name=>"user2"},
          {:type=>"user", :access=>"read", :name=>"user3"},
          {:type=>"user", :access=>"edit", :name=>"user1"}]
    end
    describe "updating permissions" do
      it "should create new group permissions" do
        subject.permissions = {:new_group_name => {'group1'=>'read'}}
        subject.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should create new user permissions" do
        subject.permissions = {:new_user_name => {'user1'=>'read'}}
        subject.permissions.should == [{:type=>"user", :access=>"read", :name=>"user1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should not replace existing groups" do
        subject.permissions = {:new_group_name=> {'group1' => 'read'}}
        subject.permissions = {:new_group_name=> {'group2' => 'read'}}
        subject.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
                                     {:type=>"group", :access=>"read", :name=>"group2"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should not replace existing users" do
        subject.permissions = {:new_user_name=>{'user1'=>'read'}}
        subject.permissions = {:new_user_name=>{'user2'=>'read'}}
        subject.permissions.should == [{:type=>"user", :access=>"read", :name=>"user1"},
                                     {:type=>"user", :access=>"read", :name=>"user2"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should update permissions on existing users" do
        subject.permissions = {:new_user_name=>{'user1'=>'read'}}
        subject.permissions = {:user=>{'user1'=>'edit'}}
        subject.permissions.should == [{:type=>"user", :access=>"edit", :name=>"user1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should update permissions on existing groups" do
        subject.permissions = {:new_group_name=>{'group1'=>'read'}}
        subject.permissions = {:group=>{'group1'=>'edit'}}
        subject.permissions.should == [{:type=>"group", :access=>"edit", :name=>"group1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
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
      @file.should respond_to(:relative_path)
      @file.should respond_to(:depositor)
    end
    it "should delegate methods to descriptive metadata" do
      @file.should respond_to(:related_url)
      @file.should respond_to(:based_near)
      @file.should respond_to(:part_of)
      @file.should respond_to(:contributor)
      @file.should respond_to(:creator)
      @file.should respond_to(:title)
      @file.should respond_to(:description)
      @file.should respond_to(:publisher)
      @file.should respond_to(:date_created)
      @file.should respond_to(:date_uploaded)
      @file.should respond_to(:date_modified)
      @file.should respond_to(:subject)
      @file.should respond_to(:language)
      @file.should respond_to(:rights)
      @file.should respond_to(:resource_type)
      @file.should respond_to(:identifier)
    end
    it "should delegate methods to characterization metadata" do
      @file.should respond_to(:format_label)
      @file.should respond_to(:mime_type)
      @file.should respond_to(:file_size)
      @file.should respond_to(:last_modified)
      @file.should respond_to(:filename)
      @file.should respond_to(:original_checksum)
      @file.should respond_to(:well_formed)
      @file.should respond_to(:file_title)
      @file.should respond_to(:file_author)
      @file.should respond_to(:page_count)
    end
    it "should redefine to_param to make redis keys more recognizable" do
      @file.to_param.should == @file.noid
    end
    describe "that have been saved" do
      # This file has no content, so it doesn't characterize
      # before(:each) do
      #   Sufia.queue.should_receive(:push).once
      # end
      after(:each) do
        unless @file.inner_object.class == ActiveFedora::UnsavedDigitalObject
          begin
            @file.delete
          rescue ActiveFedora::ObjectNotFoundError
            # do nothing
          end
        end
      end
      it "should have activity stream-related methods defined" do
        @file.save
        f = @file.reload
        f.should respond_to(:stream)
        f.should respond_to(:events)
        f.should respond_to(:create_event)
        f.should respond_to(:log_event)
      end
      it "should be able to set values via delegated methods" do
        @file.related_url = "http://example.org/"
        @file.creator = "John Doe"
        @file.title = "New work"
        @file.save
        f = @file.reload
        f.related_url.should == ["http://example.org/"]
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
      end
      it "should be able to be added to w/o unexpected graph behavior" do
        @file.creator = "John Doe"
        @file.title = "New work"
        @file.save
        f = @file.reload
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
        f.creator = "Jane Doe"
        f.title << "Newer work"
        f.save
        f = @file.reload
        f.creator.should == ["Jane Doe"]
        f.title.should == ["New work", "Newer work"]
      end
    end
  end
  it "should support to_solr" do
    @file.stub(:pid).and_return('stubbed_pid')
    @file.part_of = "Arabiana"
    @file.contributor = "Mohammad"
    @file.creator = "Allah"
    @file.title = "The Work"
    @file.description = "The work by Allah"
    @file.publisher = "Vertigo Comics"
    @file.date_created = "1200-01-01"
    @file.date_uploaded = Date.parse("2011-01-01")
    @file.date_modified = Date.parse("2012-01-01")
    @file.subject = "Theology"
    @file.language = "Arabic"
    @file.rights = "Wide open, buddy."
    @file.resource_type = "Book"
    @file.identifier = "urn:isbn:1234567890"
    @file.based_near = "Medina, Saudi Arabia"
    @file.related_url = "http://example.org/TheWork/"
    @file.mime_type = "image/jpeg"
    @file.format_label = "JPEG Image"
    local = @file.to_solr
    local.should_not be_nil
    local[Solrizer.solr_name("desc_metadata__part_of")].should be_nil
    local[Solrizer.solr_name("desc_metadata__date_uploaded")].should be_nil
    local[Solrizer.solr_name("desc_metadata__date_modified")].should be_nil
    local[Solrizer.solr_name("desc_metadata__date_uploaded", :stored_sortable, type: :date)].should == '2011-01-01T00:00:00Z'
    local[Solrizer.solr_name("desc_metadata__date_modified", :stored_sortable, type: :date)].should == '2012-01-01T00:00:00Z'
    local[Solrizer.solr_name("desc_metadata__rights")].should == ["Wide open, buddy."]
    local[Solrizer.solr_name("desc_metadata__related_url")].should be_nil
    local[Solrizer.solr_name("desc_metadata__contributor")].should == ["Mohammad"]
    local[Solrizer.solr_name("desc_metadata__creator")].should == ["Allah"]
    local[Solrizer.solr_name("desc_metadata__title")].should == ["The Work"]
    local[Solrizer.solr_name("desc_metadata__description")].should == ["The work by Allah"]
    local[Solrizer.solr_name("desc_metadata__publisher")].should == ["Vertigo Comics"]
    local[Solrizer.solr_name("desc_metadata__subject")].should == ["Theology"]
    local[Solrizer.solr_name("desc_metadata__language")].should == ["Arabic"]
    local[Solrizer.solr_name("desc_metadata__date_created")].should == ["1200-01-01"]
    local[Solrizer.solr_name("desc_metadata__resource_type")].should == ["Book"]
    local[Solrizer.solr_name("file_format")].should == "jpeg (JPEG Image)"
    local[Solrizer.solr_name("desc_metadata__identifier")].should == ["urn:isbn:1234567890"]
    local[Solrizer.solr_name("desc_metadata__based_near")].should == ["Medina, Saudi Arabia"]
    local[Solrizer.solr_name("mime_type")].should == ["image/jpeg"]    
    local["noid_tsi"].should eq('stubbed_pid')
  end
  it "should support multi-valued fields in solr" do
    @file.tag = ["tag1", "tag2"]
    lambda { @file.save }.should_not raise_error
    @file.delete
  end
  it "should support setting and getting the relative_path value" do
    @file.relative_path = "documents/research/NSF/2010"
    @file.relative_path.should == "documents/research/NSF/2010"
  end
  describe "create_thumbnail" do
    before do
      @f = GenericFile.new
      #@f.stub(:characterize_if_changed).and_yield #don't run characterization
      @f.apply_depositor_metadata('mjg36')
    end
    after do
      @f.delete
    end
    describe "with a video", :if => Sufia.config.enable_ffmpeg do
      before do
        @f.stub(:mime_type=>'video/quicktime')  #Would get set by the characterization job
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
      u = FactoryGirl.create(:user)
      @f = GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(u)
        gf.stub(:characterize_if_changed).and_yield #don't run characterization
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
    before(:each) do
      u = FactoryGirl.create(:user)
      f = GenericFile.new
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata(u)
      f.stub(:characterize_if_changed).and_yield #don't run characterization
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
      GenericFile.stub(:run_audit).and_return(double(:respose, :pass=>1, :created_at=>'2005-12-20', :pid=>'foo:123', :dsid=>'foo', :version=>'1'))
      @f.audit!
      ChecksumAuditLog.all.all? { |cal| cal.pass == 0 }.should be_true
    end
    it "should log a passing audit" do
      GenericFile.stub(:run_audit).and_return(double(:respose, :pass=>1, :created_at=>'2005-12-20', :pid=>'foo:123', :dsid=>'foo', :version=>'1'))
      @f.audit!
      ChecksumAuditLog.all.all? { |cal| cal.pass == 1 }.should be_true
    end

    it "should return true on audit_status" do
      @f.audit_stat.should be_true
    end
  end

  describe "run_audit" do
    before do
      @f = GenericFile.new
      @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @f.apply_depositor_metadata('mjg36')
      @f.stub(:characterize_if_changed).and_yield #don't run characterization
      @f.save!
      @version = @f.datastreams['content'].versions.first
      @old = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>1, :created_at=>2.minutes.ago)
      @new = ChecksumAuditLog.create(:pid=>@f.pid, :dsid=>@version.dsid, :version=>@version.versionID, :pass=>0)
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

  describe "save" do
    after(:each) do
      @file.delete
    end
    it "should schedule a characterization job" do
      @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      Sufia.queue.should_receive(:push).once
      @file.save
    end
  end
  describe "related_files" do
    before(:all) do
      @batch_id = "foobar:100"
    end
    before(:each) do
      @f1 = GenericFile.new(:pid => "foobar:1")
      @f2 = GenericFile.new(:pid => "foobar:2")
      @f3 = GenericFile.new(:pid => "foobar:3")
      @f1.apply_depositor_metadata('mjg36')
      @f2.apply_depositor_metadata('mjg36')
      @f3.apply_depositor_metadata('mjg36')
    end
    after(:each) do
      @f1.delete if @f1.persisted?
      @f2.delete if @f2.persisted?
      @f3.delete if @f3.persisted?
    end
    it "should never return a file in its own related_files method" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f3.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      @f3.save
      @f1.related_files.should_not include(@f1)
      @f1.related_files.should include(@f2)
      @f1.related_files.should include(@f3)
      @f2.related_files.should_not include(@f2)
      @f2.related_files.should include(@f1)
      @f2.related_files.should include(@f3)
      @f3.related_files.should_not include(@f3)
      @f3.related_files.should include(@f1)
      @f3.related_files.should include(@f2)
    end
    it "should return an empty array when there are no related files" do
      @f1.related_files.should == []
    end
    it "should work when batch is defined" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      mock_batch = double("batch")
      mock_batch.stub(:generic_files => [@f1, @f2])
      @f1.should_receive(:batch).and_return(mock_batch)
      @f1.related_files.should == [@f2]
    end
    it "should work when batch is not defined by querying solr" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      @f1.should_receive(:batch).twice.and_raise(NoMethodError)
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
    it "should work when batch is not defined by querying solr" do
      @f1.add_relationship(:is_part_of, "info:fedora/#{@batch_id}")
      @f2.add_relationship(:is_part_of, "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      @f1.should_receive(:batch).twice.and_raise(NoMethodError)
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
    it "should work when batch.generic_files is not defined by querying solr" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      mock_batch = double("batch")
      mock_batch.stub(:generic_files).and_raise(NoMethodError)
      @f1.should_receive(:batch).twice
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
  end
  describe "noid integration" do
    before(:all) do
      GenericFile.any_instance.should_receive(:characterize_if_changed).and_yield
      @new_file = GenericFile.new(:pid => 'ns:123')
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
    it "should return expected results when called", :unless => $in_travis do
      @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      # Without the stub(:save), the after save callback was being triggered
      # which resulted the characterize_if_changed method being called; which
      # enqueued a job for characterizing
      @file.stub(:save)
      @file.characterize
      doc = Nokogiri::XML.parse(@file.characterization.content)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should not be triggered unless the content ds is changed" do
      Sufia.queue.should_receive(:push).once
      @file.content.content = "hey"
      @file.save
      @file.related_url = 'http://example.com'
      Sufia.queue.should_receive(:push).never
      @file.save
      @file.delete
    end
    describe "after job runs" do
      before(:all) do
        myfile = GenericFile.new
        myfile.add_file(File.open(fixture_path + '/sufia/sufia_test4.pdf'), 'content', 'sufia_test4.pdf')
        myfile.label = 'label123'
        myfile.apply_depositor_metadata('mjg36')
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
      it "should include thumbnail generation in characterization job" do
        @myfile.thumbnail.size.should_not be_nil
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
      @file.label = "My New Label"
      @file.inner_object.label.should == "My New Label"
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
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      subject.rightsMetadata.groups.should == {'umg/up.dlt.staff' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read", 'jcoyne' => 'edit'}
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
        @file.permissions = {:user => {'mjg36' => 'read'}}
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(:read_users_string => 'mjg36') }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :person] => '')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via permissions()" do
        @rightsmd.permissions({:person => "mjg36"}, "read")
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"person" => {"mjg36" => "read"}})
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :person] => '')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_users)
        @file.errors[:edit_users].should include('Depositor must have edit access')
        @file.valid?.should be_false
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
        @file.permissions = {:group => {'public' => 'edit'}}
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(:edit_groups_string => 'public') }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'public')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via permissions()" do
        @rightsmd.permissions({:group => "public"}, "edit")
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"public" => "edit"}})
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'public')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Public cannot have edit access')
        @file.valid?.should be_false
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
        @file.permissions = {:group => {'registered' => 'edit'}}
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(:edit_groups_string => 'registered') }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:edit_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via permissions()" do
        @rightsmd.permissions({:group => "registered"}, "edit")
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "edit"}})
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:edit_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_true
        @file.errors.should include(:edit_groups)
        @file.errors[:edit_groups].should include('Registered cannot have edit access')
        @file.valid?.should be_false
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
        @file.permissions = {:group => {'registered' => 'read'}}
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via update_attributes" do
        # automatically triggers save
        lambda { @file.update_attributes(:read_groups_string => 'registered') }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via update_indexed_attributes" do
        @rightsmd.update_indexed_attributes([:read_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via permissions()" do
        @rightsmd.permissions({:group => "registered"}, "read")
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via update_permissions()" do
        @rightsmd.update_permissions({"group" => {"registered" => "read"}})
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via content=()" do
        @rightsmd.content=(@rights_xml)
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via ng_xml=()" do
        @rightsmd.ng_xml=(Nokogiri::XML::Document.parse(@rights_xml))
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
      it "should work via update_values()" do
        @rightsmd.update_values([:read_access, :group] => 'registered')
        lambda { @file.save }.should_not raise_error
        @file.new_object?.should be_false
        @file.errors.should be_empty
        @file.valid?.should be_true
      end
    end
  end
end
