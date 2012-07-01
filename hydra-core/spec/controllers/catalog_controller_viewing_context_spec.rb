require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe CatalogController do
  before do
    controller.stub(:load_fedora_document)
  end

  describe "show" do
    it "should redirect to edit view if session is in edit context and user has edit permission" do
      controller.stub(:can?).and_return(true)
      controller.session[:viewing_context] = "edit"
      get(:show, {:id=>"hydrangea:fixture_mods_article1"})
      response.should redirect_to(:action => 'edit')
    end
    it "should allow you to reset the session context to browse using :viewing_context param" do
      controller.stub(:can?).and_return(true)
      controller.session[:viewing_context] = "edit"
      get(:show, :id=>"hydrangea:fixture_mods_article1", :viewing_context=>"browse")
      session[:viewing_context].should == "browse"
      response.should_not redirect_to(:action => 'edit')
    end
    
    it "should quietly switch session state to browse if user does not have edit permissions" do
      controller.stub(:can?).with(:edit, anything()).and_return(false)
      controller.stub(:can?).with(:read, anything()).and_return(true)
      controller.session[:viewing_context] = "edit"
      get(:show, {:id=>"hydrangea:fixture_mods_article1"})
      session[:viewing_context].should == "browse"
      response.should_not redirect_to(:action => 'edit')
    end
  end
  
  describe "edit" do
    it "should enforce edit permissions, redirecting to show action and resetting session context if user does not have edit permissions" do
      mock_user = FactoryGirl.build(:user, :email => "patron1@example.com")
      sign_in mock_user
      
      get :edit, :id=>"hydrangea:fixture_mods_article1"
      response.should redirect_to(:action => 'show')
      flash[:alert].should == "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
    end
    it "should render normally if user has edit permissions" do
      controller.should_receive(:can?).with(:edit, anything()).and_return(true)
      get :edit, :id=>"hydrangea:fixture_mods_article1"
      response.should_not redirect_to(:action => 'show')
    end
  end
  
end
