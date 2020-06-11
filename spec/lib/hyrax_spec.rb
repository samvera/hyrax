# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax do
  describe '.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to respond_to :log
    end
  end
end
