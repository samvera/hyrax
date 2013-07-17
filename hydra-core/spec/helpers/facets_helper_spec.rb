require 'spec_helper'

describe FacetsHelper do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before(:each) do
    helper.stub(:blacklight_config).and_return blacklight_config
  end
  
  
  describe "render_selected_facet_value" do
    it "should be html_safe and not have the remove link" do
      item = double("item", :value=>'two', :hits=>9)
      ret_val = helper.render_selected_facet_value("one", item)
      ret_val.should == "<span class=\"selected\">two <span class=\"count\">9</span></span>"
      ret_val.should be_html_safe
    end
    it "should use facet_display_value" do
      item = double("item", :value=>'two', :hits=>9)
      helper.stub(:facet_display_value).and_return('four')
      ret_val = helper.render_selected_facet_value("one", item)
      ret_val.should == "<span class=\"selected\">four <span class=\"count\">9</span></span>"
    end
  end
end

