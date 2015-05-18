require 'spec_helper'

describe Sufia::Works::CurationConcern::Work do
  before do
    class EssentialWork < ActiveFedora::Base
      include Sufia::Works::CurationConcern::Work
    end
  end

  after do
    Object.send(:remove_const, :EssentialWork)
  end

  subject { EssentialWork.new }

  it "mixes together all the goodness" do
    expect(subject.class.ancestors).to include(Sufia::Works::CurationConcern::WithGenericFiles, Sufia::Works::CurationConcern::HumanReadableType, Sufia::Noid, Sufia::ModelMethods, Hydra::Collections::Collectible, Solrizer::Common)
  end

  describe "human_readable_type" do
    it "has a default" do
      expect(subject.human_readable_type).to eq 'Essential Work'
    end
    it "should be settable" do
      EssentialWork.human_readable_type = 'Custom Type'
      expect(subject.human_readable_type).to eq 'Custom Type'
    end
  end

  describe "#indexer" do
    subject { EssentialWork.indexer }
    it { is_expected.to eq Sufia::GenericWorkIndexingService }
  end
end
