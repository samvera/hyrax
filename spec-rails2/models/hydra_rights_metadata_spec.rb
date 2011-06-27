require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"
require "nokogiri"

describe Hydra::RightsMetadata do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @sample = Hydra::RightsMetadata.new
  end
  
  describe "permissions" do
    describe "setter" do
      it "should create/update/delete permissions for the given user/group" do
        @sample.class.terminology.xpath_for(:access, :person, "person_123").should == '//oxns:access/oxns:machine/oxns:person[contains(., "person_123")]'
        
        person_123_perms_xpath = @sample.class.terminology.xpath_for(:access, :person, "person_123")
        group_zzz_perms_xpath = @sample.class.terminology.xpath_for(:access, :group, "group_zzz")
        
        @sample.find_by_terms(person_123_perms_xpath).should be_empty 
        @sample.permissions({"person"=>"person_123"}, "edit").should == "edit"
        @sample.permissions({"group"=>"group_zzz"}, "edit").should == "edit"      
        
        @sample.find_by_terms(person_123_perms_xpath).first.ancestors("access").first.attributes["type"].text.should == "edit"
        @sample.find_by_terms(group_zzz_perms_xpath).first.ancestors("access").first.attributes["type"].text.should == "edit"
        
        @sample.permissions({"person"=>"person_123"}, "read")
        @sample.permissions({"group"=>"group_zzz"}, "read")
        @sample.find_by_terms(person_123_perms_xpath).length.should == 1
        
        @sample.find_by_terms(person_123_perms_xpath).first.ancestors("access").first.attributes["type"].text.should == "read"
        @sample.find_by_terms(group_zzz_perms_xpath).first.ancestors("access").first.attributes["type"].text.should == "read"
      
        @sample.permissions({"person"=>"person_123"}, "none").should == "none"
        @sample.permissions({"group"=>"group_zzz"}, "none").should == "none"
        @sample.find_by_terms(person_123_perms_xpath).should be_empty 
        @sample.find_by_terms(person_123_perms_xpath).should be_empty 
      end
      it "should remove existing permissions (leaving only one permission level per user/group)" do
        person_123_perms_xpath = @sample.class.terminology.xpath_for(:access, :person, "person_123")
        group_zzz_perms_xpath = @sample.class.terminology.xpath_for(:access, :group, "group_zzz")
                        
        @sample.find_by_terms(person_123_perms_xpath).length.should == 0
        @sample.find_by_terms(group_zzz_perms_xpath).length.should == 0
        @sample.permissions({"person"=>"person_123"}, "read")
        @sample.permissions({"group"=>"group_zzz"}, "read")
        @sample.find_by_terms(person_123_perms_xpath).length.should == 1
        @sample.find_by_terms(group_zzz_perms_xpath).length.should == 1
        
        @sample.permissions({"person"=>"person_123"}, "edit")
        @sample.permissions({"group"=>"group_zzz"}, "edit")
        @sample.find_by_terms(person_123_perms_xpath).length.should == 1
        @sample.find_by_terms(group_zzz_perms_xpath).length.should == 1
      end
      it "should not impact other users permissions" do
        @sample.permissions({"person"=>"person_123"}, "read")
        @sample.permissions({"person"=>"person_789"}, "edit")
        
        @sample.permissions({"person"=>"person_123"}).should == "read"
        @sample.permissions({"person"=>"person_456"}, "read")
        @sample.permissions({"person"=>"person_123"}).should == "read"
        @sample.permissions({"person"=>"person_456"}).should == "read"
        @sample.permissions({"person"=>"person_789"}).should == "edit"
        
        
      end
    end
    describe "getter" do
      it "should return permissions level for the given user/group" do
        @sample.permissions({"person"=>"person_123"}, "edit")
        @sample.permissions({"group"=>"group_zzz"}, "discover")
        @sample.permissions({"person"=>"person_123"}).should == "edit"
        @sample.permissions({"group"=>"group_zzz"}).should == "discover"
        @sample.permissions({"group"=>"foo_people"}).should == "none"
      end
    end
  end
  describe "groups" do
    it "should return a hash of all groups with permissions set, along with their permission levels" do
      @sample.permissions({"group"=>"group_zzz"}, "edit")
      @sample.permissions({"group"=>"public"}, "discover")

      #@sample.groups.should == {"group_zzz"=>"edit", "public"=>"discover"}
      @sample.groups.should == {"public"=>"discover", "group_zzz"=>"edit"}
    end
  end
  describe "individuals" do
    it "should return a hash of all individuals with permissions set, along with their permission levels" do
      @sample.permissions({"person"=>"person_123"}, "read")
      @sample.permissions({"person"=>"person_456"}, "edit")
      @sample.individuals.should == {"person_123"=>"read", "person_456"=>"edit"}
    end
  end
  
  describe "update_permissions" do
    it "should accept a hash of groups and persons, updating their permissions accordingly" do
      @sample.expects(:permissions).with({"group" => "group1"}, "discover")
      @sample.expects(:permissions).with({"group" => "group2"}, "edit")
      @sample.expects(:permissions).with({"person" => "person1"}, "read")
      @sample.expects(:permissions).with({"person" => "person2"}, "discover")
      
      @sample.update_permissions( {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}} )
    end
  end
  
  describe "update_indexed_attributes" do
    it "should update the declared properties" do
      @sample.find_by_terms(*[:edit_access, :person]).length.should == 0
      @sample.update_values([:edit_access, :person]=>"user id").should == {"edit_access_person"=>{"0"=>"user id"}}
      @sample.find_by_terms(*[:edit_access, :person]).length.should == 1
      @sample.find_by_terms(*[:edit_access, :person]).first.text.should == "user id"
    end
  end
  describe "to_solr" do
    it "should populate solr doc with the correct fields" do
      params = {[:edit_access, :person]=>"Lil Kim", [:edit_access, :group]=>["group1","group2"], [:discover_access, :group]=>["public"],[:discover_access, :person]=>["Joe Schmoe"]}
      @sample.update_values(params)
      solr_doc = @sample.to_solr
      
      solr_doc["edit_access_person_t"].should == ["Lil Kim"]
      solr_doc["edit_access_group_t"].sort.should == ["group1", "group2"]
      solr_doc["discover_access_person_t"].should == ["Joe Schmoe"]
      solr_doc["discover_access_group_t"].should == ["public"]
    end
    it "should solrize fixture content correctly" do
      fixture_xml = Nokogiri::XML::Document.parse( fixture("hydrangea_fixture_mods_article1.foxml.xml") )
      fixture_rights = fixture_xml.xpath("//foxml:datastream[@ID='rightsMetadata']/foxml:datastreamVersion[last()]/foxml:xmlContent").first.to_xml
      lsample = Hydra::RightsMetadata.from_xml(fixture_rights)
      solr_doc = lsample.to_solr
      solr_doc["edit_access_person_t"].should == ["researcher1"]
      solr_doc["edit_access_group_t"].should == ["archivist"]
      solr_doc["read_access_group_t"].should == ["public"]
      solr_doc["discover_access_group_t"].should == ["public"]
    end
  end
  describe "embargo_release_date=" do
    it "should update the appropriate node with the value passed" do
      @sample.embargo_release_date=("2010-12-01")
      @sample.embargo_release_date.should == "2010-12-01"
    end
    it "should only accept valid date values" do
      
    end
  end
  describe "embargo_release_date" do
    it "should return the value as specified in the appropriate node" do
    end
  end
  describe "under_embargo?" do
    it "should return true if the current date is before the embargo release date" do
      @sample.embargo_release_date=Date.today+1.month
      @sample.under_embargo?.should be_true
    end
    it "should return false if the current date is after the embargo release date" do
      @sample.embargo_release_date=Date.today-1.month
      @sample.under_embargo?.should be_false
    end
    it "should return false if there is no embargo date" do
      @sample.under_embargo?.should be_false
    end
  end
end
