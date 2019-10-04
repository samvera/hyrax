require 'spec_helper'

RSpec.describe Hyrax::VirusScanner do
  let(:file)   { '/tmp/path' }
  let(:logger) { Logger.new(nil) }

  before { allow(Hyrax).to receive(:logger).and_return(logger) }

  subject { described_class.new(file) }

  context 'when ClamAV is defined' do
    before do
      class Clamby
        def self.virus?(path)
          puts "scanfile: #{path}"
        end
      end
    end
    after do
      Object.send(:remove_const, :Clamby)
    end
    context 'with a clean file' do
      before { allow(Clamby).to receive(:virus?).with('/tmp/path').and_return(false) }
      it 'returns false with no warning' do
        expect(Hyrax.logger).not_to receive(:warn)
        is_expected.not_to be_infected
      end
    end
    context 'with an infected file' do
      before { allow(Clamby).to receive(:virus?).with('/tmp/path').and_return(true) }
      it 'returns true with a warning' do
        expect(Hyrax.logger).to receive(:warn).with(kind_of(String))
        is_expected.to be_infected
      end
    end
  end

  context 'when Clamby is not defined' do
    before { Object.send(:remove_const, :Clamby) if defined?(Clamby) }

    it 'returns false with a warning' do
      expect(Hyrax.logger).to receive(:warn).with(kind_of(String))
      is_expected.not_to be_infected
    end
  end
end
