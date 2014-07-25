require 'spec_helper'

describe Hydra::ModelMethods do

  before :all do
    class TestModel < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::ModelMethods
      has_metadata "properties", type: Hydra::Datastream::Properties
    end
  end

  subject { TestModel.new }

  describe "apply_depositor_metadata" do
    it "should add edit access" do
      subject.apply_depositor_metadata('naomi')
      expect(subject.rightsMetadata.users).to eq('naomi' => 'edit')
    end
    it "should not overwrite people with edit access" do
      subject.rightsMetadata.permissions({:person=>"jessie"}, 'edit')
      subject.apply_depositor_metadata('naomi')
      expect(subject.rightsMetadata.users).to eq('naomi' => 'edit', 'jessie' =>'edit')
    end
    it "should set depositor" do
      subject.apply_depositor_metadata('chris')
      expect(subject.properties.depositor).to eq ['chris']
    end
    it "should accept objects that respond_to? :user_key" do
      stub_user = double(:user, :user_key=>'monty')
      subject.apply_depositor_metadata(stub_user)
      expect(subject.properties.depositor).to eq ['monty']
    end
  end

  describe 'add_file' do
    let(:file_name) { "my_file.foo" }
    let(:mock_file) { "File contents" }

    it "should set the dsid, mimetype and content" do
      expect(subject).to receive(:add_file_datastream).with(mock_file, label: file_name, mime_type: "mymimetype", dsid: 'bar')
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      expect(MIME::Types).to receive(:of).with(file_name).and_return([double(content_type: "mymimetype")])
      subject.add_file(mock_file, 'bar', file_name)
    end

    it "should accept a supplied mime_type and content" do
      expect(subject).to receive(:add_file_datastream).with(mock_file, label: file_name, mime_type: "image/png", dsid: 'bar')
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      subject.add_file(mock_file, 'bar', file_name, 'image/png')
    end
  end
end
