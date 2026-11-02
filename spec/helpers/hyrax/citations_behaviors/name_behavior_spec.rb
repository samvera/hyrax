# frozen_string_literal: true
RSpec.describe Hyrax::CitationsBehaviors::NameBehavior do
  subject(:behavior) { Class.new { include Hyrax::CitationsBehaviors::NameBehavior }.new }

  describe '#surname_first' do
    it 'moves the given name after the surnames' do
      expect(behavior.surname_first('Gary Jordan')).to eq('Jordan, Gary')
    end

    it 'leaves a name that already has a comma alone' do
      expect(behavior.surname_first('Jordan, Gary')).to eq('Jordan, Gary')
    end

    it 'leaves a single-word name alone' do
      expect(behavior.surname_first('Cher')).to eq('Cher')
    end
  end

  describe '#abbreviate_name' do
    it 'abbreviates the given name' do
      expect(behavior.abbreviate_name('Gary Jordan')).to eq('Jordan, G.')
    end

    it 'leaves a single-word name alone' do
      expect(behavior.abbreviate_name('Cher')).to eq('Cher')
    end
  end
end
