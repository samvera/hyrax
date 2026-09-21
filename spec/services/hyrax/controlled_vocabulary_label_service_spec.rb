# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::ControlledVocabularyLabelService do
  subject(:service) { described_class.new }

  describe '#labels_for' do
    it 'returns the values unchanged' do
      expect(service.labels_for('resource_types', ['local_auth_123', 'Image']))
        .to eq(['local_auth_123', 'Image'])
    end

    it 'wraps a single value in an array' do
      expect(service.labels_for('resource_types', 'local_auth_123')).to eq(['local_auth_123'])
    end

    it 'returns an empty array for no values' do
      expect(service.labels_for('resource_types', nil)).to eq([])
    end
  end

  describe '#resolvable?' do
    it 'resolves nothing, so no property is treated as controlled' do
      expect(service.resolvable?('resource_types')).to be false
    end
  end
end
