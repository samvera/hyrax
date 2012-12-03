require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# This uses nokogiri to check formedness. It's slightly less strict than the markup_validit
# currently not being used. 
def well_formed(html)
  begin
    Nokogiri::XML(html.gsub("&", "&amp;" )) { |config| config.strict } #Literal & in text are not allowed, but we don't care. 
    return "ok"
  rescue Nokogiri::XML::SyntaxError => e
    # Write the offensive HTML to a file in tmp/html_validity_failures with a filename based on Time.now.iso8601
    html_failures_dir = File.expand_path(File.dirname(__FILE__) + '/../../tmp/html_validity_failures')
    FileUtils.mkdir_p(html_failures_dir)
    filename = Time.now.iso8601(3).gsub(":","")+".html"
    file_path = File.join(html_failures_dir, filename)
    file = File.open(file_path, "w")
    file.write(html)
    return "#{e.inspect} -- Line: #{e.line} -- Level: #{e.level} -- Code: #{e.code}.  HTML Saved to RAILS_ROOT/tmp/html_validity_failures/#{filename}"
  end
end



# This checks document for validity (if required) and well formedness  
# Pass in a html string. IF you want to check for XHTML validity, do rake spec HTML_VALIDITY=true. Otherwise only document form is checked
# by nokogiri.  
def document_check(html, html_validity=ENV["HTML_VALIDITY"])
  if html_validity == "true" || html_validity == true
    html.should be_xhtml_transitional
  end
  well_formed(html).should == "ok"
end


describe CatalogController do
  describe "Home Page" do
    
    it "Should have Valid HTML when not logged in" do
      get("index", "controller"=>"catalog")
      document_check(response.body)
    end
    
    it "Should have Valid HTML when I'm logged in" do
        sign_in FactoryGirl.build(:user, :email=>"archivist1@example.com")
        get("index", "controller"=>"catalog")
        document_check(response.body)
    end
  end

  describe "Document Pages" do 
    
    before(:each)  do
        mock_user = FactoryGirl.build(:user, :email=>"archivist1@example.com")
        sign_in mock_user
    end
    
    it "Should have valid html when in Article Browse Show" do 
       get(:show, {:id=>"hydrangea:fixture_mods_article1"})
       document_check(response.body)
    end
    
    it "Should have valid html when in Dataset Browse Show" do 
      get(:show, {:id=>"hydrangea:fixture_mods_dataset1"})
      document_check(response.body)
    end
    
    it "Should have valid html when in Dataset Browse Show" do 
      get(:show, {:id=>"hydrus:admin_class1"})
      File.open('/tmp/out.xml', 'w') { |f| f << response.body }
      document_check(response.body)
    end
    
    # The delete view should be the same for all data types
    it "Should have valid html when in Dataset Delete" do 
       get(:show, {:id=>"hydrangea:fixture_mods_dataset1"}, :action=>"delete")
       document_check(response.body)
    end
    
    
  end #Document pages
  
end
