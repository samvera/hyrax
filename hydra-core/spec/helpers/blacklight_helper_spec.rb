require 'spec_helper'

describe BlacklightHelper do
  describe "document_partial_name" do
    it "should lop off everything before the first colin after the slash" do
      @config = Blacklight::Configuration.new.configure do |config|
        config.show.display_type = 'has_model_s'
      end
      helper.stub(:blacklight_config).and_return(@config)
      helper.document_partial_name('has_model_s' => ["info:fedora/afmodel:Presentation"]).should == "presentation"
      helper.document_partial_name('has_model_s' => ["info:fedora/hull-cModel:genericContent"]).should == "generic_content" 
    end
    it "should support single valued fields" do
      @config = Blacklight::Configuration.new.configure do |config|
        config.show.display_type = 'active_fedora_model_ssi'
      end
      helper.stub(:blacklight_config).and_return(@config)
      helper.document_partial_name('active_fedora_model_ssi' => "Chicken").should == "chicken" 
    end

    it "should handle periods" do
      @config = Blacklight::Configuration.new.configure do |config|
        config.show.display_type = 'has_model_s'
      end
      helper.stub(:blacklight_config).and_return(@config)
      helper.document_partial_name('has_model_s' => ["info:fedora/afmodel:text.PDF"]).should == "text_pdf"
    end
  end
  
end
