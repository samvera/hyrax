require 'spec_helper'

describe Sufia::Arkivo::CreateSubscriptionJob do
  let(:user) { FactoryGirl.find_or_create(:archivist) }

  subject { described_class.new(user.user_key) }

  context 'with a bogus user' do
    before { allow(User).to receive(:find_by_user_key) { nil } }
    it 'raises because user not found' do
      expect { subject.run }.to raise_error(Sufia::Arkivo::SubscriptionError, 'User not found')
    end
  end

  context 'without an arkivo token' do
    before { allow_any_instance_of(User).to receive(:arkivo_token) { nil } }
    it 'raises because user lacks arkivo token' do
      expect { subject.run }.to raise_error(Sufia::Arkivo::SubscriptionError, 'User does not have an Arkivo token')
    end
  end

  context 'without a zotero userid' do
    it 'raises because user did not oauth' do
      expect { subject.run }.to raise_error(Sufia::Arkivo::SubscriptionError, 'User has not yet connected with Zotero')
    end
  end

  context 'with an existing subscription' do
    before do
      allow_any_instance_of(User).to receive(:zotero_userid) { '45352' }
      allow_any_instance_of(User).to receive(:arkivo_subscription) { 'http://localhost/foo/bar' }
    end

    it 'raises because user already has subscription' do
      expect { subject.run }.to raise_error(Sufia::Arkivo::SubscriptionError, 'User already has a subscription')
    end
  end

  context 'when expected to succeed' do
    before do
      allow_any_instance_of(User).to receive(:zotero_userid) { '45352' }
      allow(subject).to receive(:post_to_api) { response }
    end

    let(:response) { double('response', headers: { 'Location' => subscription_uri }) }
    let(:subscription_uri) { '/api/subscription/abcxyz1234' }

    it 'stores a subscription URL for possible later invalidation' do
      expect(user.arkivo_subscription).to be_blank
      subject.run
      expect(user.reload.arkivo_subscription).to eq subscription_uri
    end
  end
end
