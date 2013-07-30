require 'spec_helper'

describe SufiaHelper do
  describe "link_to_profile" do
    it "should use User#to_params" do
      u = User.new
      u.stub(:user_key).and_return('justin@example.com')
      User.should_receive(:find_by_user_key).with('justin@example.com').and_return(u)
      helper.link_to_profile('justin@example.com').should == "<a href=\"/users/justin@example-dot-com\">justin@example.com</a>"
    end
  end

  describe "selected facet" do
    let(:blacklight_config) { Blacklight::Configuration.new }

    before(:each) do
      helper.stub(:blacklight_config).and_return blacklight_config
      helper.stub(:url_for).and_return('http://example.com')
    end


    describe "render_selected_facet_value" do
      it "be html_safe and not have the remove link" do
        item = double("item", :value=>'two', :hits=>9)
        ret_val = helper.render_facet_value("one", item)
        doc = Nokogiri::HTML(ret_val)
        filter = doc.xpath("//a[@class='facet_select']")
        filter.text.should == item.value
        ret_val.should be_html_safe
      end
      it "use facet_display_value" do
        item = double("item", :value=>'two', :hits=>9)
        helper.stub(:facet_display_value).and_return('four')
        ret_val = helper.render_facet_value("one", item)
        doc = Nokogiri::HTML(ret_val)
        filter = doc.xpath("//a[@class='facet_select']")
        filter.text.should == 'four'
      end
      it "use facet_display_value for dashboard" do
        params[:controller] = "dashboard"
        item = double("item", :value=>'two', :hits=>9)
        helper.stub(:facet_display_value).and_return('four')
        ret_val = helper.render_facet_value("one", item)
        doc = Nokogiri::HTML(ret_val)
        filter = doc.xpath("//a[@class='facet_select']")
        filter.text.should == 'four'
      end

    end
  end
end
