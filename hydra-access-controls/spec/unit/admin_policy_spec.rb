require 'spec_helper'

describe Hydra::AdminPolicy do
  before do
    Hydra.stub(:config).and_return({:permissions=>{
      :catchall => "access_t",
      :discover => {:group =>"discover_access_group_t", :individual=>"discover_access_person_t"},
      :read => {:group =>"read_access_group_t", :individual=>"read_access_person_t"},
      :edit => {:group =>"edit_access_group_t", :individual=>"edit_access_person_t"},
      :owner => "depositor_t",
      :embargo_release_date => "embargo_release_date_dt",
      
      :inheritable => {
        :catchall => "inheritable_access_t",
        :discover => {:group =>"inheritable_discover_access_group_t", :individual=>"inheritable_discover_access_person_t"},
        :read => {:group =>"inheritable_read_access_group_t", :individual=>"inheritable_read_access_person_t"},
        :edit => {:group =>"inheritable_edit_access_group_t", :individual=>"inheritable_edit_access_person_t"},
        :owner => "inheritable_depositor_t",
        :embargo_release_date => "inheritable_embargo_release_date_dt"
      }
    }})
  end
  its(:defaultRights) { should be_kind_of Hydra::Datastream::InheritableRightsMetadata}
  its(:rightsMetadata) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:descMetadata) { should be_kind_of ActiveFedora::QualifiedDublinCoreDatastream}

  describe "when setting attributes" do
    before do
      subject.title = "My title" 
      subject.description = "My description" 
      subject.license_title = "My license" 
      subject.license_description = "My license desc" 
      subject.license_url = "My url" 
    end
    its(:title) { should == "My title"}
    its(:description) { should == "My description"}
    its(:license_title) { should == "My license"}
    its(:license_description) { should == "My license desc"}
    its(:license_url) { should == "My url"}
  end
    

  describe "to_solr" do
    subject { Hydra::AdminPolicy.new(:title=>"Foobar").to_solr }
    it "should have title_t" do
      subject["title_t"].should == ['Foobar']
    end
    it "should have title_display" do
      subject["title_display"].should == 'Foobar'
    end
  end
  
  describe "Inheritable rights" do
    before do
      @policy = Hydra::AdminPolicy.new
      @policy.default_permissions = [{:name=>"africana-faculty", :access=>"edit", :type=>"group"}, {:name=>"cool-kids", :access=>"edit", :type=>"group"}, {:name=>"julius_caesar", :access=>"edit", :type=>"user"}]
      @policy.default_permissions = [{:name=>"slightlycoolkids", :access=>"read", :type=>"group"}, {:name=>"nero", :access=>"read", :type=>"user"}]
      @policy.default_permissions = [{:name=>"posers", :access=>"discover", :type=>"group"}, {:name=>"constantine", :access=>"discover", :type=>"user"}]
      @policy.defaultRights.embargo_release_date = "2102-10-01"
    end

    describe "to_solr" do
      subject {@policy.to_solr}
      it "should not affect normal solr permissions fields" do    
        subject.should_not have_key( Hydra.config[:permissions][:catchall] )
        subject.should_not have_key( Hydra.config[:permissions][:discover][:group] ) 
        subject.should_not have_key( Hydra.config[:permissions][:discover][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:read][:group] )
        subject.should_not have_key( Hydra.config[:permissions][:read][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:edit][:group] )
        subject.should_not have_key( Hydra.config[:permissions][:edit][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:embargo_release_date] )
      end
      it "should provide prefixed/inherited solr permissions fields" do
        subject[Hydra.config[:permissions][:inheritable][:catchall] ].should == ["posers", "slightlycoolkids", "africana-faculty", "cool-kids", "constantine", "nero", "julius_caesar"] 
        subject[Hydra.config[:permissions][:inheritable][:discover][:group] ].should == ["posers"]
        subject[Hydra.config[:permissions][:inheritable][:discover][:individual] ].should == ["constantine"]
        subject[Hydra.config[:permissions][:inheritable][:read][:group] ].should == ["slightlycoolkids"]
        subject[Hydra.config[:permissions][:inheritable][:read][:individual] ].should == ["nero"]
        subject[Hydra.config[:permissions][:inheritable][:edit][:group] ].should == ["africana-faculty", "cool-kids"]
        subject[Hydra.config[:permissions][:inheritable][:edit][:individual] ].should == ["julius_caesar"]
        subject[Hydra.config[:permissions][:inheritable][:embargo_release_date] ].should == "2102-10-01"
      end
    end

  end


end
