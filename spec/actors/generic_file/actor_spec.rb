require 'spec_helper'

describe Sufia::GenericFile::Actor do
  describe "#virus_check" do
    it "should return the results of running ClamAV scanfile method" do
      expect(ClamAV.instance).to receive(:scanfile).and_return(1)
      expect { Sufia::GenericFile::Actor.virus_check(File.new(fixture_path + '/world.png')) }.to raise_error(Sufia::VirusFoundError)
    end
  end

  describe "#featured_work" do
    let(:user) { FactoryGirl.create(:user) }
    let(:gf) { FactoryGirl.create(:generic_file, visibility: 'open') }
    let(:actor) { Sufia::GenericFile::Actor.new(gf, user)}

    before { FeaturedWork.create(generic_file_id: gf.noid) }

    after { gf.destroy }

    it "should be removed if document is not public" do
      # Switch document from public to restricted
      attributes = {'permissions'=>{'group' =>{'public' => '1', 'registered'=>'2'}}}
      expect { actor.update_metadata(attributes, 'restricted') }.to change { FeaturedWork.count }.by(-1)
    end
  end

end
