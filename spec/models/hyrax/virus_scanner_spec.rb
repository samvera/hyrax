# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::VirusScanner, :virus_scan do
  let(:file)   { '/tmp/path' }
  let(:logger) { Logger.new(nil) }

  before { allow(Hyrax).to receive(:logger).and_return(logger) }

  subject { described_class.new(file) }

  context 'when Clamby is defined' do # Included in test app's Gemfile
    context 'with a clean file' do
      before { allow(Clamby::Command).to receive(:scan).with('/tmp/path').and_return(false) }
      it 'returns false with no warning' do
        expect(Hyrax.logger).not_to receive(:warn)
        is_expected.not_to be_infected
      end
    end
    context 'with an infected file' do
      before { allow(Clamby::Command).to receive(:scan).with('/tmp/path').and_return(true) }
      it 'returns true with a warning' do
        expect(Hyrax.logger).to receive(:warn).with(kind_of(String))
        is_expected.to be_infected
      end
    end
  end

  context 'when Clamby is not defined' do
    it 'returns false' do
      hide_const('Clamby')
      # we used to test the warning here, but we suppress it for the test env now
      is_expected.not_to be_infected
    end
  end
end
