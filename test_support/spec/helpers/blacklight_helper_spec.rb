require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlacklightHelper do
  
  describe "Overridden blacklight methods" do
    describe "document_partial_name" do

      it "Should lop off everything before the first colin after the slash" do
    @config = Blacklight::Configuration.new.configure do |config|
      config.show.display_type = 'has_model_s'
    end
        helper.stubs(:blacklight_config).returns(@config)
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
    
    describe "link back to catalog" do
      it "should return the view parameter in the link back to catalog method if there is one in the users previous search session" do
        session[:search] = {:view=>"list"}
        helper.link_back_to_catalog.should match(/\?view=list/)
      end
      it "should not return the view parameter if it wasn't provided" do
        session[:search] = {}
        helper.link_back_to_catalog.should_not match(/\?view=/)
      end
    end
  end
  
  describe "SALT methods" do
    describe "get_data_with_linked_label" do
      before(:each) do
        @doc = {"field"=>["Item1","Item2","Item3"]}
      end
      it "should return a string representing the collection of items with the suplied delimiter" do
        helper.get_data_with_linked_label(@doc,"Items","field",{:delimiter=>", "}).should match(/, /)
      end
      it "should return a string representing the collection of items with the default <br/> delimiter" do
        helper.get_data_with_linked_label(@doc,"Items","field").should match(/<br\/>/)
      end
    end
  end
  
end
