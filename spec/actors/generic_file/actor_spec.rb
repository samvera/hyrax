require 'spec_helper'

describe Sufia::GenericFile::Actor do
  describe "#virus_check" do
    it "should return the results of running ClamAV scanfile method" do
      ClamAV.instance.should_receive(:scanfile).and_return(1)
      expect { Sufia::GenericFile::Actor.virus_check(File.new(fixture_path + '/world.png')) }.to raise_error(Sufia::VirusFoundError)
    end
  end
end
