require 'spec_helper'

describe User, type: :model, no_clean: true do
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

  describe '#to_sipity_agent' do
    it 'will find or create a Sipity::Agent' do
      user.save!
      expect { user.to_sipity_agent }.to change { Sipity::Agent.count }.by(1)
    end

    it 'will fail if the User is not persisted' do
      expect { user.to_sipity_agent }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
