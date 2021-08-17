# frozen_string_literal: true
RSpec.describe Hyrax::NullUser do
  subject(:null_user) { described_class.new }

  describe '#id' do
    it 'returns fake id' do
      expect(subject.id).to eq '_NULL_USER_ID_'
    end
  end

  describe '#user_key' do
    it 'returns nil' do
      expect(subject.user_key).to eq nil
    end
  end
end
