require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'RedCloth'
include HydraHelper


describe HydraHelper do
  
  describe "link_to_multifacet" do
    #"box_facet"=>["7"]
    it "should create a link to a catalog search with the desired facets" do
      CGI.unescape(link_to_multifacet("my link", "series_facet" => "7", "box_facet" => ["41"])).should == "<a href=\"/catalog?f[box_facet][]=41&amp;f[series_facet][]=7\">my link</a>"
    end
  end
  
  describe "get_html_data_with_label" do
    before(:all) do
      @default_html = " &lt;p&gt;Default Hello&lt;/p&gt;&lt;ol&gt;
           &lt;li&gt;1&lt;/li&gt;
           &lt;li&gt;2&lt;/li&gt;

           &lt;li&gt;3&lt;/li&gt;
           &lt;li&gt;
             &lt;em&gt;strong&lt;/em&gt;
           &lt;/li&gt;
         &lt;/ol&gt;"
      @sample_document = {'story_display' => [" &lt;p&gt;Hello&lt;/p&gt;&lt;ol&gt;
          &lt;li&gt;1&lt;/li&gt;
          &lt;li&gt;2&lt;/li&gt;

          &lt;li&gt;3&lt;/li&gt;
          &lt;li&gt;
            &lt;em&gt;strong&lt;/em&gt;
          &lt;/li&gt;
        &lt;/ol&gt;"],'relation_t'=>['http://example.com','"Salt Dev":https://salt-dev.stanford.edu/catalog']}
    end
    it "should return unescaped html from story_display field" do    
     text = get_html_data_with_label(@sample_document,"Stories:", 'story_display')
     text.should match(/^<dt>Stories:<\/dt><dd>/) and  # Begin with <dt> label
     text.should match(/<p>Hello<\/p>/) and # have HTML
     text.should_not match(/&lt;p&gt;Hello&lt;\/p&gt;/) and #NOT have escaped html
     text.should match(/<\/dd>$/) # ends with closing </dd>
    end
    
    it "should return unescaped html from default option if one is passed and the given field doesn't exist in the edoc" do
      text = get_html_data_with_label(@sample_document,"Stories:", 'no_story_display',{:default=>@default_html})
      text.should match(/^<dt>Stories:<\/dt><dd>/) and  # Begin with <dt> label
      text.should match(/<p>Default Hello<\/p>/) and # have HTML with Default in the text
      text.should_not match(/<p>Hello<\/p>/) and # NOT have the text from the document
      text.should_not match(/&lt;p&gt;Default Hello&lt;\/p&gt;/) and #NOT have escaped html
      text.should match(/<\/dd>$/) # ends with closing </dd>
    end  
    it "should return the unescaped document html if the given field exists even if the default option is passed" do
      doc_text = get_html_data_with_label(@sample_document,"Stories:", 'story_display',{:default=>@default_html})
      doc_text.should match(/<p>Hello<\/p>/) and
      doc_text.should_not match(/<p>Default Hello<\/p>/)
    end
  end
  
  describe "get_textile_data_with_label" do
    before(:all) do
      @sample_document = {'relation_t'=>['http://example.com','"Salt Dev":https://salt-dev.stanford.edu/catalog']}
    end
    it "should return html-rendered textile data" do
      doc_text = get_textile_data_with_label(@sample_document,"Links:", 'relation_t')
      doc_text.should match(/<dt>Links:<\/dt><dd>/) and
      doc_text.should match(/<p>http:\/\/example.com<\/p>/) and
      doc_text.should match(/<br\/>/) and
      doc_text.should match('<p><a href="https://salt-dev.stanford.edu/catalog">Salt Dev</a></p><br/>') and
      doc_text.should match(/<\/dd>/)
    end
  end
  
  describe "submit_name" do
    it "should return 'Save' when the scripts session variable is set" do
      stubs(:session).returns({:scripts=>true})
      submit_name.should == "Save"
    end
    it "should return 'Continue' when the new_asset param is set" do
      stubs(:params).returns({:new_asset=>true})
      submit_name.should == "Continue"
    end
    it "should return 'Save and Continue' if all else fails" do
      submit_name.should == "Save and Continue"
    end
  end
  
end