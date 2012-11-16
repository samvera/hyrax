# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe GenericFile do
  before(:each) do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @file = GenericFile.new
    @file.apply_depositor_metadata('jcoyne')
  end
  describe "attributes" do
    it "should have rightsMetadata" do
      @file.rightsMetadata.should be_instance_of ParanoidRightsDatastream
    end
    it "should have properties datastream for depositor" do
      @file.properties.should be_instance_of PropertiesDatastream
    end
    it "should have apply_depositor_metadata" do
      @file.rightsMetadata.edit_access.should == ['jcoyne']
      @file.depositor.should == 'jcoyne'
    end
    it "should have a set of permissions" do
      @file.read_groups=['group1', 'group2']
      @file.edit_users=['user1']
      @file.read_users=['user2', 'user3']
      @file.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
          {:type=>"group", :access=>"read", :name=>"group2"},
          {:type=>"user", :access=>"read", :name=>"user2"},
          {:type=>"user", :access=>"read", :name=>"user3"},
          {:type=>"user", :access=>"edit", :name=>"user1"}]
    end
    describe "updating permissions" do
      it "should create new group permissions" do
        @file.permissions = {:new_group_name => {'group1'=>'read'}}
        @file.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should create new user permissions" do
        @file.permissions = {:new_user_name => {'user1'=>'read'}}
        @file.permissions.should == [{:type=>"user", :access=>"read", :name=>"user1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should not replace existing groups" do
        @file.permissions = {:new_group_name=> {'group1' => 'read'}}
        @file.permissions = {:new_group_name=> {'group2' => 'read'}}
        @file.permissions.should == [{:type=>"group", :access=>"read", :name=>"group1"},
                                     {:type=>"group", :access=>"read", :name=>"group2"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should not replace existing users" do
        @file.permissions = {:new_user_name=>{'user1'=>'read'}}
        @file.permissions = {:new_user_name=>{'user2'=>'read'}}
        @file.permissions.should == [{:type=>"user", :access=>"read", :name=>"user1"},
                                     {:type=>"user", :access=>"read", :name=>"user2"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should update permissions on existing users" do
        @file.permissions = {:new_user_name=>{'user1'=>'read'}}
        @file.permissions = {:user=>{'user1'=>'edit'}}
        @file.permissions.should == [{:type=>"user", :access=>"edit", :name=>"user1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
      it "should update permissions on existing groups" do
        @file.permissions = {:new_group_name=>{'group1'=>'read'}}
        @file.permissions = {:group=>{'group1'=>'edit'}}
        @file.permissions.should == [{:type=>"group", :access=>"edit", :name=>"group1"},
                                     {:type=>"user", :access=>"edit", :name=>"jcoyne"}]
      end
    end
    it "should have a characterization datastream" do
      @file.characterization.should be_kind_of FitsDatastream
    end
    it "should have a dc desc metadata" do
      @file.descMetadata.should be_kind_of GenericFileRdfDatastream
    end
    it "should have content datastream" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.content.should be_kind_of FileContentDatastream
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
      @file.should respond_to(:format)
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
      before(:each) do
        Resque.expects(:enqueue).once.returns(true)
      end
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
        f = GenericFile.find(@file.pid)
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
        f = GenericFile.find(@file.pid)
        f.related_url.should == ["http://example.org/"]
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
      end
      it "should be able to be added to w/o unexpected graph behavior" do
        @file.creator = "John Doe"
        @file.title = "New work"
        @file.save
        f = GenericFile.find(@file.pid)
        f.creator.should == ["John Doe"]
        f.title.should == ["New work"]
        f.creator = "Jane Doe"
        f.title << "Newer work"
        f.save
        f = GenericFile.find(@file.pid)
        f.creator.should == ["Jane Doe"]
        f.title.should == ["New work", "Newer work"]
      end
    end
  end
  it "should support to_solr" do
    @file.part_of = "Arabiana"
    @file.contributor = "Mohammad"
    @file.creator = "Allah"
    @file.title = "The Work"
    @file.description = "The work by Allah"
    @file.publisher = "Vertigo Comics"
    @file.date_created = "1200"
    @file.date_uploaded = "2011"
    @file.date_modified = "2012"
    @file.subject = "Theology"
    @file.language = "Arabic"
    @file.rights = "Wide open, buddy."
    @file.resource_type = "Book"
    @file.format = "application/pdf"
    @file.identifier = "urn:isbn:1234567890"
    @file.based_near = "Medina, Saudi Arabia"
    @file.related_url = "http://example.org/TheWork/"
    local = @file.to_solr
    local.should_not be_nil
    local["generic_file__part_of_t"].should be_nil
    local["generic_file__date_uploaded_t"].should be_nil
    local["generic_file__date_modified_t"].should be_nil
    local["generic_file__rights_t"].should == ["Wide open, buddy."]
    local["generic_file__related_url_t"].should be_nil
    local["generic_file__contributor_t"].should == ["Mohammad"]
    local["generic_file__creator_t"].should == ["Allah"]
    local["generic_file__title_t"].should == ["The Work"]
    local["generic_file__description_t"].should == ["The work by Allah"]
    local["generic_file__publisher_t"].should == ["Vertigo Comics"]
    local["generic_file__subject_t"].should == ["Theology"]
    local["generic_file__language_t"].should == ["Arabic"]
    local["generic_file__date_created_t"].should == ["1200"]
    local["generic_file__resource_type_t"].should == ["Book"]
    local["generic_file__format_t"].should == ["application/pdf"]
    local["generic_file__identifier_t"].should == ["urn:isbn:1234567890"]
    local["generic_file__based_near_t"].should == ["Medina, Saudi Arabia"]
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
    describe "with an image that doesn't get resized" do
      before do
        @f = GenericFile.new
        @f.stubs(:mime_type=>'image/png', :width=>['50'], :height=>['50'])  #Would get set by the characterization job
        @f.stubs(:to_solr).returns({})
        @f.add_file_datastream(File.new("#{Rails.root}/spec/fixtures/world.png"), :dsid=>'content')
        @f.apply_depositor_metadata('mjg36')
        @f.save
        @mock_image = mock("image", :from_blob=>true)
        Magick::ImageList.expects(:new).returns(@mock_image)
      end
      after do
        @f.delete
      end
      it "should scale the thumbnail to original size" do
        @mock_image.expects(:scale).with(50, 50).returns(stub(:to_blob=>'fake content'))
        @f.create_thumbnail
        @f.content.changed?.should be_false
        @f.thumbnail.content.should == 'fake content'
      end
    end
  end
  describe "audit" do
    before(:all) do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
      GenericFile.any_instance.stubs(:characterize).returns(true)
      f = GenericFile.new
      f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      f.apply_depositor_metadata('mjg36')
      f.save
      @f = GenericFile.find(f.pid)
      @datastreams = [FileContentDatastream, ActiveFedora::RelsExtDatastream,
                      ActiveFedora::Datastream, PropertiesDatastream,
                      ParanoidRightsDatastream]
    end
    after(:all) do
      @f.delete
    end
    it "should schedule a audit job" do
      @datastreams.each { |ds| ds.any_instance.stubs(:dsChecksumValid).returns(false) }
      ChecksumAuditLog.stubs(:create!).returns(true)
      Resque.expects(:enqueue).times(@datastreams.count)
      @f.audit!
    end
    it "should log a failing audit" do
      @datastreams.each { |ds| ds.any_instance.stubs(:dsChecksumValid).returns(false) }
      @f.audit!
      ChecksumAuditLog.all.all? { |cal| cal.pass == 0 }.should be_true
    end
    it "should log a passing audit" do
      @datastreams.each { |ds| ds.any_instance.stubs(:dsChecksumValid).returns(true) }
      @f.audit!
      ChecksumAuditLog.all.all? { |cal| cal.pass == 1 }.should be_true
    end
    it "should return true on audit_status" do
      @f.audit_stat.should be_true
    end
  end
  describe "save" do
    after(:each) do
      @file.delete
    end
    it "should schedule a characterization job" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      Resque.expects(:enqueue).once
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
      mock_batch = mock("batch")
      mock_batch.stubs(:generic_files => [@f1, @f2])
      @f1.expects(:batch).returns(mock_batch)
      @f1.related_files.should == [@f2]
    end
    it "should work when batch is not defined by querying solr" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      @f1.expects(:batch).twice.raises(NoMethodError)
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
    it "should work when batch is not defined by querying solr" do
      @f1.add_relationship(:is_part_of, "info:fedora/#{@batch_id}")
      @f2.add_relationship(:is_part_of, "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      @f1.expects(:batch).twice.raises(NoMethodError)
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
    it "should work when batch.generic_files is not defined by querying solr" do
      @f1.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f2.add_relationship("isPartOf", "info:fedora/#{@batch_id}")
      @f1.save
      @f2.save
      mock_batch = mock("batch")
      mock_batch.stubs(:generic_files).raises(NoMethodError)
      @f1.expects(:batch).twice
      lambda { @f1.related_files }.should_not raise_error
      @f1.related_files.should == [@f2]
    end
  end
  describe "noid integration" do
    before(:all) do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
      GenericFile.any_instance.expects(:characterize_if_changed).yields
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
    it "should return expected results when called" do
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.characterize
      doc = Nokogiri::XML.parse(@file.characterization.content)
      doc.root.xpath('//ns:imageWidth/text()', {'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output'}).inner_text.should == '50'
    end
    it "should not be triggered unless the content ds is changed" do
      Resque.expects(:enqueue).once
      @file.content.content = "hey"
      @file.save
      @file.related_url = 'http://example.com'
      Resque.expects(:enqueue).never
      @file.save
      @file.delete
    end
    describe "after job runs" do
      before(:all) do
        GenericFile.any_instance.stubs(:terms_of_service).returns('1')
        myfile = GenericFile.new
        myfile.add_file_datastream(File.new(Rails.root + 'spec/fixtures/scholarsphere/scholarsphere_test4.pdf'), :dsid=>'content')
        myfile.label = 'label123'
        myfile.thumbnail.size.nil?.should be_true
        myfile.apply_depositor_metadata('mjg36')
        myfile.save
        @myfile = GenericFile.find(myfile.pid)
      end
      after(:all) do
        unless @myfile.inner_object.kind_of? ActiveFedora::UnsavedDigitalObject
          begin
            @myfile.delete
          rescue ActiveFedora::ObjectNotFoundError
            # do nothing
          end
        end
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
        @myfile.thumbnail.size.nil?.should be_false
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
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read"}
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      subject.rightsMetadata.groups.should == {'umg/up.dlt.staff' => 'read', 'group-3'=>'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read"}
    end
    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      subject.rightsMetadata.groups.should == {'group-2' => 'read', 'group-3'=>'read', 'group-7' => 'read', 'group-8' => 'edit'}
      subject.rightsMetadata.individuals.should == {"person1"=>"read","person2"=>"read"}
    end
  end
  describe "permissions validation" do
    context "depositor must have edit access" do
      before(:each) do
        GenericFile.any_instance.stubs(:terms_of_service).returns('1')
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
        GenericFile.any_instance.stubs(:terms_of_service).returns('1')
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
        GenericFile.any_instance.stubs(:terms_of_service).returns('1')
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
        GenericFile.any_instance.stubs(:terms_of_service).returns('1')
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
