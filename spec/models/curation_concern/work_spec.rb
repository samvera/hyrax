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

  it "should mix together all the goodness" do
    [Sufia::Works::CurationConcern::WithGenericFiles, Sufia::Works::CurationConcern::HumanReadableType, Sufia::Noid, Sufia::ModelMethods, Hydra::Collections::Collectible, Solrizer::Common].each do |mixin|
      expect(subject.class.ancestors).to include(mixin)
    end
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

  it "inherits (and extends) to_solr behaviors from superclass" do
    expect(subject.to_solr.keys).to include(:id)
    expect(subject.to_solr.keys).to include("has_model_ssim")
  end
end
