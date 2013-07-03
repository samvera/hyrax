require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::RenderConstraintsHelperBehavior do

  describe "render_filter_element" do
    let(:blacklight_config) { Blacklight::Configuration.new }

    before(:each) do
      helper.stub(:blacklight_config).and_return blacklight_config
    end


    describe "render_selected_facet_value" do
      it "be html_safe and not have the remove link" do
        item = double("item", :value=>'two', :hits=>9)
        ret_val = helper.render_filter_element("one", [item],{})
        doc = Nokogiri::HTML(ret_val.first)
        filter = doc.xpath("//span[@class='filterValue']")
        filter.text.should == item.value
      end
      it "use facet_display_value" do
        helper.stub(:facet_display_value).and_return('four')
        item = double("item", :value=>'two', :hits=>9)
        ret_val = helper.render_filter_element("one", [item],{})
        doc = Nokogiri::HTML(ret_val.first)
        filter = doc.xpath("//span[@class='filterValue']")
        filter.text.should == 'four'
      end
      it "use facet_display_value for dashboard" do
        params[:controller] = "dashboard"
        helper.stub(:facet_display_value).and_return('four')
        helper.stub(:dashboard_index_path).and_return("abc")
        item = double("item", :value=>'two', :hits=>9)
        ret_val = helper.render_filter_element("one", [item],{})
        doc = Nokogiri::HTML(ret_val.first)
        filter = doc.xpath("//span[@class='filterValue']")
        filter.text.should == 'four'
      end

    end
  end
end
