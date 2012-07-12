require 'spec_helper'

describe BlacklightHelper do
  describe "document_partial_name" do
    it "Should lop off everything before the first colin after the slash" do
      @config = Blacklight::Configuration.new.configure do |config|
        config.show.display_type = 'has_model_s'
      end
      helper.stub(:blacklight_config).and_return(@config)
      helper.document_partial_name('has_model_s' => ["info:fedora/afmodel:Presentation"]).should == "presentations"
      helper.document_partial_name('has_model_s' => ["info:fedora/hull-cModel:genericContent"]).should == "generic_contents" 
    end
  end
  
end
