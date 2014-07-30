require 'spec_helper'

describe Sufia::Permissions::Writable do

  class SampleModel < ActiveFedora::Base
    include Sufia::Permissions::Writable
  end
  let(:subject) { SampleModel.new }

  it "should initialized with a parnoid rightsMetadata datastream" do
    expect(subject.rightsMetadata).to be_kind_of ParanoidRightsDatastream
  end

  describe "#permissions" do
    it "should initialize with nothing specified" do
      expect(subject.permissions).to be_empty
    end
  end

end
