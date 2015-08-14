require 'spec_helper'

describe CurationConcerns::Permissions::Writable do
  class SampleModel < ActiveFedora::Base
    include CurationConcerns::Permissions::Writable
  end
  let(:subject) { SampleModel.new }

  describe '#permissions' do
    it 'initializes with nothing specified' do
      expect(subject.permissions).to be_empty
    end
  end
end
