require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ability do

  it "should call custom_permissions" do
      Ability.any_instance.expects(:custom_permissions)
      ability = Ability.new(nil)
      ability.can?(:delete, 7)
  end
end
