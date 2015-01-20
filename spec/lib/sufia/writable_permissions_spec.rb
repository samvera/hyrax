require 'spec_helper'

describe Sufia::Permissions::Writable do

  class SampleModel < ActiveFedora::Base
    include Sufia::Permissions::Writable
  end
  let(:subject) { SampleModel.new }

  describe "#permissions" do
    it "should initialize with nothing specified" do
      expect(subject.permissions).to be_empty
    end
  end

end
