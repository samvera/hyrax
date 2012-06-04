require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe GenericImage do
  
  subject { GenericImage.new(:pid=>'test:pid')}
  
  it "Should be a kind of ActiveFedora::Base" do
    subject.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should include Hydra Model Methods" do
    subject.class.included_modules.should include(Hydra::ModelMethods)
    subject.should respond_to(:apply_depositor_metadata)
  end
  
  it "should include Hydra Generic Image Methods" do
    subject.class.included_modules.should include(Hydra::GenericImage)
    subject.should respond_to(:derivation_options)
  end
  
  it "should have accessors for its default datastreams of content and original" do
    subject.should respond_to(:has_content?)
    subject.should respond_to(:content)
    subject.should respond_to(:content=)
    subject.should respond_to(:has_original?)
    subject.should respond_to(:original)
    subject.should respond_to(:original=)
  end
  
  it "should have accessors for its default datastreams of max, screen and thumbnail" do
    subject.should respond_to(:has_max?)
    subject.should respond_to(:max)
    subject.should respond_to(:max=)
    subject.should respond_to(:has_screen?)
    subject.should respond_to(:screen)
    subject.should respond_to(:screen=)
    subject.should respond_to(:has_thumbnail?)
    subject.should respond_to(:thumbnail)
    subject.should respond_to(:thumbnail=)
  end

  it "should create a max datastream when setting max value to image file" do
    f = File.new(File.join( File.dirname(__FILE__), "../../fixtures/image.jp2" ))
    subject.max = f
  end
  
  describe '#content=' do
    it "should create a content datastream when given an image file" 
  end

  describe '#derive_all' do
    it "should create a max, screen and thumbnail file"
  end

  its(:datastream_url) { should == 'http://127.0.0.1:8983/fedora-test/objects/test:pid/datastreams/content/content' }
  its(:admin_site) { should == 'http://127.0.0.1:8983/' }

  
end
