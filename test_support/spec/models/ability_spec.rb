require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ability do
  it "should call custom_permissions" do
    Ability.any_instance.expects(:custom_permissions)
    subject = Ability.new(nil) 
    subject.can?(:delete, 7)
  end

  context "for a not-signed in user" do
    subject { Ability.new(nil) }
    it "should be able to read objects that are public" do
      public_object = ModsAsset.new
      public_object.rightsMetadata.update_permissions("group"=>{'public'=>'read'}) 
      public_object.save
      subject.can?(:read, public_object).should be_true
    end
    it "should not be able to read objects that are registered" do
      registered_object = ModsAsset.new
      registered_object.rightsMetadata.update_permissions("group"=>{'registered'=>'read'}) 
      registered_object.save
      subject.can?(:read, registered_object).should_not be_true
    end
  end
  context "for a signed in user" do
    subject { Ability.new(FactoryGirl.create(:user)) }
    it "should be able to read objects that are public" do
      public_object = ModsAsset.new
      public_object.rightsMetadata.update_permissions("group"=>{'public'=>'read'}) 
      public_object.save
      subject.can?(:read, public_object).should be_true
    end
    it "should be able to read objects that are registered" do
      registered_object = ModsAsset.new
      registered_object.rightsMetadata.update_permissions("group"=>{'registered'=>'read'}) 
      registered_object.save
      subject.can?(:read, registered_object).should be_true
    end
  end
end
