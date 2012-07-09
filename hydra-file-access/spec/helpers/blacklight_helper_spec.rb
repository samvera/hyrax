require 'spec_helper'

describe BlacklightHelper do
  
  describe "Overridden blacklight methods" do
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
    describe "render_selected_facet_value" do
      it "should be html_safe and not have the remove link" do
        item = stub("item", :value=>'two', :hits=>9)

        ret_val = helper.render_selected_facet_value("one", item)
        ret_val.should == "<span class=\"selected\">two <span class=\"count\">(9)</span></span>"
        ret_val.should be_html_safe
      end
    end
  end
  
end
