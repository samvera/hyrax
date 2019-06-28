# frozen_string_literal: true

RSpec.describe Hyrax::EmbargoManager do
  subject(:manager) { described_class.new(resource: resource) }
  let(:resource)    { Hyrax::Resource.new }

  shared_context 'when under embargo' do
    let(:resource) { FactoryBot.create(:embargoed_work).valkyrie_resource }
  end

  describe '#apply' do
    it 'is a no-op for inactive embargo' do
      expect { manager.apply }
        .not_to change { resource.visibility }
    end

    context 'when under embargo' do
      include_context 'when under embargo'

      before { resource.visibility = 'open' }

      it 'applies the active embargo visibility' do
        expect { manager.apply }
          .to change { resource.visibility }
          .to 'restricted'
      end
    end
  end

  describe '#embargo' do
    it 'gives an inactive embargo' do
      expect(manager.embargo).not_to be_active
    end

    context 'when under embargo' do
      include_context 'when under embargo'

      it 'gives an active embargo' do
        expect(manager.embargo).to be_active
      end

      it 'has embargo attributes' do
        expect(manager.embargo)
          .to have_attributes visibility_after_embargo: 'open',
                              visibility_during_embargo: 'restricted',
                              embargo_release_date: an_instance_of(DateTime),
                              embargo_history: be_empty
      end
    end
  end

  describe '#under_embargo?' do
    it { is_expected.not_to be_under_embargo }

    context 'when under embargo' do
      include_context 'when under embargo'

      it { is_expected.to be_under_embargo }
    end
  end
end
