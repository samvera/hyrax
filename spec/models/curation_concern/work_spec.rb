require 'spec_helper'

describe CurationConcern::Work do
  before do
    class EssentialWork < ActiveFedora::Base
      include CurationConcern::Work 
    end
  end
  after do
    Object.send(:remove_const, :EssentialWork)
  end

  subject { EssentialWork.new }

  it "should mix together all the goodness" do
    [::CurationConcern::WithGenericFiles, ::CurationConcern::HumanReadableType, Hydra::AccessControls::Permissions, ::CurationConcern::Embargoable, ::CurationConcern::WithEditors, Sufia::Noid, Sufia::ModelMethods, Hydra::Collections::Collectible, Solrizer::Common].each do |mixin|
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
end
