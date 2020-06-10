# frozen_string_literal: true
RSpec.describe Hyrax::Permissions::Writable do
  class SampleModel < ActiveFedora::Base
    include Hyrax::Permissions::Writable
  end
  let(:subject) { SampleModel.new }

  describe '#permissions' do
    it 'initializes with nothing specified' do
      expect(subject.permissions).to be_empty
    end
  end
end
