require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::ModelMethods do
  
  before :all do
    class TestModel < ActiveFedora::Base
      include Hydra::ModelMixins::CommonMetadata
      include Hydra::ModelMethods
    end
  end

  describe "apply_depositor_metadata" do
    subject {TestModel.new }
    it "should add edit access" do
      subject.apply_depositor_metadata('naomi')
      subject.rightsMetadata.individuals.should == {'naomi' => 'edit'}
    end
    it "should not overwrite people with edit access" do
      subject.rightsMetadata.permissions({:person=>"jessie"}, 'edit')
      subject.apply_depositor_metadata('naomi')
      subject.rightsMetadata.individuals.should == {'naomi' => 'edit', 'jessie' =>'edit'}
    end
  end

end
