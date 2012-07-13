require 'spec_helper'

describe FacetsHelper do
  
  describe "render_selected_facet_value" do
    it "should be html_safe and not have the remove link" do
      item = stub("item", :value=>'two', :hits=>9)

      ret_val = helper.render_selected_facet_value("one", item)
      ret_val.should == "<span class=\"selected\">two <span class=\"count\">(9)</span></span>"
      ret_val.should be_html_safe
    end
  end
end

