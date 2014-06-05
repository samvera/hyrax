require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::Datastream::InheritableRightsMetadata do
  before do
    Hydra.stub(:config).and_return(
      Hydra::Config.new.tap do |config|
        config.permissions ={
          :discover => {:group =>"discover_access_group_ssim", :individual=>"discover_access_person_ssim"},
          :read => {:group =>"read_access_group_ssim", :individual=>"read_access_person_ssim"},
          :edit => {:group =>"edit_access_group_ssim", :individual=>"edit_access_person_ssim"},
          :owner => "depositor_ssim",
          :embargo_release_date => "embargo_release_date_dtsi",

          :inheritable => {
            :discover => {:group =>"inheritable_discover_access_group_ssim", :individual=>"inheritable_discover_access_person_ssim"},
            :read => {:group =>"inheritable_read_access_group_ssim", :individual=>"inheritable_read_access_person_ssim"},
            :edit => {:group =>"inheritable_edit_access_group_ssim", :individual=>"inheritable_edit_access_person_ssim"},
            :owner => "inheritable_depositor_ssim",
            :embargo_release_date => "inheritable_embargo_release_date_dtsi"
          }
        }
      end
    )
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
      subject.should_not have_key( Hydra.config[:permissions][:discover][:group] ) 
      subject.should_not have_key( Hydra.config[:permissions][:discover][:individual] )
      subject.should_not have_key( Hydra.config[:permissions][:read][:group] )
      subject.should_not have_key( Hydra.config[:permissions][:read][:individual] )
      subject.should_not have_key( Hydra.config[:permissions][:edit][:group] )
      subject.should_not have_key( Hydra.config[:permissions][:edit][:individual] )
      subject.should_not have_key( Hydra.config[:permissions][:embargo_release_date] )
    end
    it "should provide prefixed/inherited solr permissions fields" do
      subject[Hydra.config[:permissions][:inheritable][:discover][:group] ].should == ["posers"]
      subject[Hydra.config[:permissions][:inheritable][:discover][:individual] ].should == ["constantine"]
      subject[Hydra.config[:permissions][:inheritable][:read][:group] ].should == ["slightly-cool-kids"]
      subject[Hydra.config[:permissions][:inheritable][:read][:individual] ].should == ["nero"]
      subject[Hydra.config[:permissions][:inheritable][:edit][:group] ].should == ["africana-faculty", "cool-kids"]
      subject[Hydra.config[:permissions][:inheritable][:edit][:individual] ].should == ["julius_caesar"]
      expect(subject[Hydra.config[:permissions][:inheritable][:embargo_release_date]]).to eq Date.parse("2102-10-01").to_time.utc.iso8601
    end
  end

end
