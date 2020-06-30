# frozen_string_literal: true

RSpec.describe Hyrax::FormFactory do
  subject(:factory) { described_class.new }
  let(:model)       { FactoryBot.build(:hyrax_work) }

  describe '.build' do
    let(:ability)    { :FAKE_ABILITY }
    let(:controller) { :FAKE_CONTROLLER }

    it 'returns a change set' do
      expect(factory.build(model, ability, controller)).to be_a Hyrax::ChangeSet
    end

    context 'when the work is persisted' do
      let(:model) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'prepopulates the changeset with a lock token' do
        expect(factory.build(model, ability, controller))
          .to have_attributes(version: an_instance_of(String))
      end
    end
  end
end
