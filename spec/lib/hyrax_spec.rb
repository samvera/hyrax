# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax do
  describe '.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to respond_to :log
    end
  end

  describe '.collection_classes' do
    it 'returns all possible collection classes' do
      expect(described_class.collection_classes)
        .to match_array [::Collection, Hyrax::PcdmCollection]
    end
  end
end
