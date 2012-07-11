require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "nokogiri"

describe Hydra::Datastream::InheritableRightsMetadata do
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
  
  before(:each) do
    # The way RubyDora loads objects prevents us from stubbing the fedora connection :(
    # ActiveFedora::RubydoraConnection.stubs(:instance).returns(stub_everything())
    obj = ActiveFedora::Base.new
    @sample = Hydra::Datastream::InheritableRightsMetadata.new(obj.inner_object, nil)
    @sample.stub(:content).and_return('')

    @sample.permissions({:group=>"africana-faculty"}, "edit")
    @sample.permissions({:group=>"cool-kids"}, "edit")
    @sample.permissions({:group=>"slightly-cool-kids"}, "read")
    @sample.permissions({:group=>"posers"}, "discover")
    @sample.permissions({:person=>"julius_caesar"}, "edit") 
    @sample.permissions({:person=>"nero"}, "read") 
    @sample.permissions({:person=>"constantine"}, "discover") 
    @sample.embargo_release_date = "2102-10-01"
  end

  describe "to_solr" do
    subject {@sample.to_solr}
    it "should NOT provide normal solr permissions fields" do    
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
      subject[Hydra.config[:permissions][:inheritable][:catchall] ].should == ["posers", "slightly-cool-kids", "africana-faculty", "cool-kids", "constantine", "nero", "julius_caesar"] 
      subject[Hydra.config[:permissions][:inheritable][:discover][:group] ].should == ["posers"]
      subject[Hydra.config[:permissions][:inheritable][:discover][:individual] ].should == ["constantine"]
      subject[Hydra.config[:permissions][:inheritable][:read][:group] ].should == ["slightly-cool-kids"]
      subject[Hydra.config[:permissions][:inheritable][:read][:individual] ].should == ["nero"]
      subject[Hydra.config[:permissions][:inheritable][:edit][:group] ].should == ["africana-faculty", "cool-kids"]
      subject[Hydra.config[:permissions][:inheritable][:edit][:individual] ].should == ["julius_caesar"]
      subject[Hydra.config[:permissions][:inheritable][:embargo_release_date] ].should == "2102-10-01"
    end
  end

end
