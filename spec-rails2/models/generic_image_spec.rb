require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe GenericImage do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @hydra_image = GenericImage.new

  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @hydra_image.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should include Hydra Model Methods" do
    @hydra_image.class.included_modules.should include(Hydra::ModelMethods)
    @hydra_image.should respond_to(:apply_depositor_metadata)
  end
  
  it "should have accessors for its default datastreams of content and original" do
    @hydra_image.should respond_to(:has_content?)
    @hydra_image.should respond_to(:content)
    @hydra_image.should respond_to(:content=)
    @hydra_image.should respond_to(:has_original?)
    @hydra_image.should respond_to(:original)
    @hydra_image.should respond_to(:original=)
  end
  
  it "should have accessors for its default datastreams of max, screen and thumbnail" do
    @hydra_image.should respond_to(:has_max?)
    @hydra_image.should respond_to(:max)
    @hydra_image.should respond_to(:max=)
    @hydra_image.should respond_to(:has_screen?)
    @hydra_image.should respond_to(:screen)
    @hydra_image.should respond_to(:screen=)
    @hydra_image.should respond_to(:has_thumbnail?)
    @hydra_image.should respond_to(:thumbnail)
    @hydra_image.should respond_to(:thumbnail=)
  end

  it "should create a max datastream when setting max value to image file" do
    f = File.new(File.join( File.dirname(__FILE__), "../fixtures/image.jp2" ))
    @hydra_image.max = f
  end
  
  describe '#content=' do
    it "shoutld create a content datastream when given an image file" do
    end
  end

  describe '#derive_all' do
    it "should create a max, screen and thumbnail file" do 
    end
  end

  
end
