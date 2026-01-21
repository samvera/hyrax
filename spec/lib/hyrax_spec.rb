# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax do
  describe '.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to respond_to :log
    end
  end

  describe '.deprecator' do
    it 'is a deprecator' do
      expect(described_class.deprecator).to respond_to(:warn)
    end

    it 'can take an argument' do
      default_deprecator = described_class.deprecator
      four_deprecator = described_class.deprecator(4)
      expect(default_deprecator.deprecation_horizon).to eq('6.0')
      expect(four_deprecator.deprecation_horizon).to eq('4.0')
    end
  end
end
