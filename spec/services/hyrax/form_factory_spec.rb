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
  end
end
