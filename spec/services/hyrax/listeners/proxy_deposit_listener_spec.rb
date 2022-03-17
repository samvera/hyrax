# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::ProxyDepositListener do
  subject(:listener) { described_class.new }
  let(:data)         { { object: resource, user: depositor } }
  let(:depositor)    { FactoryBot.create(:user) }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:proxied_to)   { FactoryBot.create(:user) }
  let(:resource)     { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: proxied_to.user_key) }

  describe 'on_object_deposited' do
    let(:event_type) { :on_object_deposited }

    context 'when object has been deposited as proxy for another user' do
      it 'is a deprecated no-op' do
        expect(Deprecation).to receive(:warn).at_least(:once)
        expect { listener.on_object_deposited(event) }
          .not_to have_enqueued_job
      end
    end
  end
end
