# frozen_string_literal: true

RSpec.describe Hyrax::Listeners::ProxyDepositListener do
  subject(:listener) { described_class.new }
  let(:data)         { { object: resource, user: depositor } }
  let(:depositor)    { FactoryBot.create(:user) }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:proxied_to)   { FactoryBot.create(:user) }
  let(:resource)     { FactoryBot.valkyrie_create(:hyrax_resource) }

  describe 'on_object_deposited' do
    let(:event_type) { :on_object_deposited }

    it 'with no on_behalf_of' do
      expect { listener.on_object_deposited(event) }
        .not_to have_enqueued_job
    end

    context 'when object has been deposited as proxy for another user' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: proxied_to.user_key) }

      it 'enqueues a ContentDepositorChangeEventJob' do
        expect { listener.on_object_deposited(event) }
          .to have_enqueued_job(ContentDepositorChangeEventJob)
          .with(resource, proxied_to)
      end
    end

    context 'if user has mangaed to proxy to self' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: depositor.user_key, depositor: depositor.user_key) }

      it 'does not enqueue' do
        expect { listener.on_object_deposited(event) }
          .not_to have_enqueued_job(ContentDepositorChangeEventJob)
      end
    end

    context 'if proxying to a missing user' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, on_behalf_of: 'uncreated_proxy_target_user', depositor: depositor.user_key) }

      it 'enqueues the job (this facilitates remediation)' do
        expect { listener.on_object_deposited(event) }
          .to have_enqueued_job(ContentDepositorChangeEventJob)
          .with(resource, nil)
      end
    end
  end
end
