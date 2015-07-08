require 'spec_helper'

describe CurationConcerns::VirusDetectionService do
  let(:file) { File.new(fixture_path + '/world.png') }
  describe "#run" do
    it "calls #detect_viruses" do
      expect(described_class).to receive(:detect_viruses).with(file)
      described_class.run(file)
    end
  end
  describe "#detect_viruses" do
    it "should return the results of running ClamAV scanfile method" do
      expect(ClamAV.instance).to receive(:scanfile).and_return(1)
      expect { described_class.detect_viruses(file) }.to raise_error(CurationConcerns::VirusFoundError)
    end
  end
end
