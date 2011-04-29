require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  include ApplicationHelper
  
  describe "Application Name Sanity Check" do
    it "should have the application correct name" do 
      pending
      application_name.should == "Hydrus"
    end 
    
    it "should not be call hydrangea, blacklight, salt, ect." do 
      application_name.should_not match(/Blacklight/)
      #application_name.should_not  == "Hydrangea (Hydra Demo App)"
      application_name.should_not match(/SALT/)
      
    end
  end
    
  
  describe "Overridden blacklight methods" do
    describe "link_to_document" do
      before(:each)do
        @mock_doc = mock('mock doc')
        @mock_doc.expects(:[]).with(:id).returns("123456")
      end
      it "passes on the title attribute to the link_to_with_data method" do
        link_to_document(@mock_doc,:label=>"Some crazy long label...",:title=>"Some crazy longer label").should match(/title=\"Some crazy longer label\"/)
      end
      it "doesn't add an erroneous title attribute if one isn't provided" do
        link_to_document(@mock_doc,:label=>"Some crazy long label...").should_not match(/title=/)
      end
    end
    
    describe "link back to catalog" do
      it "should return the view parameter in the link back to catalog method if there is one in the users previous search session" do
        session[:search] = {:view=>"list"}
        link_back_to_catalog.should match(/\?view=list/)
      end
      it "should not return the view parameter if it wasn't provided" do
        session[:search] = {}
        link_back_to_catalog.should_not match(/\?view=/)
      end
    end
  end
  
  describe "SALT methods" do
    describe "get_data_with_linked_label" do
      before(:each) do
        @doc = {"field"=>["Item1","Item2","Item3"]}
      end
      it "should return a string representing the collection of items with the suplied delimiter" do
        get_data_with_linked_label(@doc,"Items","field",{:delimiter=>", "}).should match(/, /)
      end
      it "should return a string representing the collection of items with the default <br/> delimiter" do
        get_data_with_linked_label(@doc,"Items","field").should match(/<br\/>/)
      end
    end
  end
  
end