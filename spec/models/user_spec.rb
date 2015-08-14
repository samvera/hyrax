require 'spec_helper'

describe User, type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:another_user) { FactoryGirl.build(:user) }

  it 'has an email' do
    expect(user.user_key).to be_kind_of String
  end

  describe '#to_param' do
    let(:user) { described_class.new(email: 'jilluser@example.com') }

    it 'overrides to_param to make keys more recognizable in redis (and useable within Rails URLs)' do
      expect(user.to_param).to eq('jilluser@example-dot-com')
    end
  end

  it 'has a cancan ability defined' do
    expect(user).to respond_to(:can?)
  end
end
