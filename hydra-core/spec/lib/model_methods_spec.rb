require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::ModelMethods do
  
  before :all do
    class TestModel < ActiveFedora::Base
      include Hydra::ModelMixins::CommonMetadata
      include Hydra::ModelMethods
      has_metadata :name => "properties", :type => Hydra::Datastream::Properties
    end
  end

  subject {TestModel.new }

  describe "apply_depositor_metadata" do
    it "should add edit access" do
      subject.apply_depositor_metadata('naomi')
      subject.rightsMetadata.individuals.should == {'naomi' => 'edit'}
    end
    it "should not overwrite people with edit access" do
      subject.rightsMetadata.permissions({:person=>"jessie"}, 'edit')
      subject.apply_depositor_metadata('naomi')
      subject.rightsMetadata.individuals.should == {'naomi' => 'edit', 'jessie' =>'edit'}
    end
    it "should set depositor" do
      subject.apply_depositor_metadata('chris')
      subject.properties.depositor.should == ['chris']
    end
    it "should accept objects that respond_to? :user_key" do
      stub_user = double(:user, :user_key=>'monty')
      subject.apply_depositor_metadata(stub_user)
      subject.properties.depositor.should == ['monty']
    end
  end

  describe 'add_file' do
    it "should set the dsid, mimetype and content" do
      file_name = "my_file.foo"
      mock_file = "File contents"
      subject.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid=>'bar')
      subject.should_receive(:set_title_and_label).with( file_name, :only_if_blank=>true )
      MIME::Types.should_receive(:of).with(file_name).and_return([double(:content_type=>"mymimetype")])
      subject.add_file(mock_file, 'bar', file_name)
    end
  end
end
