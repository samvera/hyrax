RSpec.describe Hyrax::Permissions::Writable do
  class SampleModel < Valkyrie::Resource
    include Hyrax::Permissions::Writable
  end
  let(:subject) { SampleModel.new }

  describe 'permissions' do
    it 'initializes with nothing specified' do
      expect(subject.read_users).to be_empty
      expect(subject.read_groups).to be_empty
      expect(subject.edit_users).to be_empty
      expect(subject.edit_groups).to be_empty
    end
  end
end
