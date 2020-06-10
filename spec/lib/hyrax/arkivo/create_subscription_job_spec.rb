# frozen_string_literal: true
RSpec.describe Hyrax::Arkivo::CreateSubscriptionJob do
  let(:user) { create(:user) }

  context 'with a bogus user' do
    before { allow(User).to receive(:find_by_user_key) { nil } }
    it 'raises because user not found' do
      expect { described_class.perform_now(user.user_key) }.to raise_error(Hyrax::Arkivo::SubscriptionError, 'User not found')
    end
  end

  context 'without an arkivo token' do
    before { allow_any_instance_of(User).to receive(:arkivo_token) { nil } }
    it 'raises because user lacks arkivo token' do
      expect { described_class.perform_now(user.user_key) }.to raise_error(Hyrax::Arkivo::SubscriptionError, 'User does not have an Arkivo token')
    end
  end

  context 'without a zotero userid' do
    it 'raises because user did not oauth' do
      expect { described_class.perform_now(user.user_key) }.to raise_error(Hyrax::Arkivo::SubscriptionError, 'User has not yet connected with Zotero')
    end
  end

  context 'with an existing subscription' do
    before do
      allow_any_instance_of(User).to receive(:zotero_userid) { '45352' }
      allow_any_instance_of(User).to receive(:arkivo_subscription) { 'http://localhost/foo/bar' }
    end

    it 'raises because user already has subscription' do
      expect { described_class.perform_now(user.user_key) }.to raise_error(Hyrax::Arkivo::SubscriptionError, 'User already has a subscription')
    end
  end

  context 'when expected to succeed' do
    before do
      allow_any_instance_of(User).to receive(:zotero_userid) { '45352' }
      allow_any_instance_of(described_class).to receive(:post_to_api) { response }
    end

    let(:response) { double('response', headers: { 'Location' => subscription_uri }) }
    let(:subscription_uri) { '/api/subscription/abcxyz1234' }

    it 'stores a subscription URL for possible later invalidation' do
      expect(user.arkivo_subscription).to be_blank
      described_class.perform_now(user.user_key)
      expect(user.reload.arkivo_subscription).to eq subscription_uri
    end
  end
end
