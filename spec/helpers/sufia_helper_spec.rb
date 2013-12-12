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

  describe "number_of_deposits" do
    let(:conn) { ActiveFedora::SolrService.instance.conn }
    before do
      # More than 10 times, because the pagination threshold is 10
      12.times do |t|
        conn.add  :id => "199#{t}", Solrizer.solr_name('depositor', :stored_searchable) => user.user_key
      end
      conn.commit
    end
    after do
      12.times do |t|
        conn.delete_by_id "199#{t}"
      end
      conn.commit
    end

    let(:user) { double(user_key: 'justin') }

    it "should return the correct number" do
      expect(number_of_deposits(user)).to eq 12
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
