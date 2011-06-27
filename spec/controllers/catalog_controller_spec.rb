require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'mocha'


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe CatalogController do
  
  before do
    #controller.stubs(:protect_from_forgery).returns("meh")
    session[:user]='bob'
  end
  
  it "should use CatalogController" do
    controller.should be_an_instance_of(CatalogController)
  end
  
  
  
  it "should be restful" do
    route_for(:controller=>'catalog', :action=>'index').should == '/'
    # route_for(:controller=>'catalog', :action=>'index').should == '/catalog'
    route_for(:controller=>'catalog', :action=>'show', :id=>"test:3").should == '/catalog/test:3'
    route_for(:controller=>'catalog', :action=>'edit', :id=>"test:3").should == '/catalog/test:3/edit'
    route_for(:controller=>'catalog', :action=>'delete', :id=>"test:3").should == "/catalog/test:3/delete"
        
    params_from(:get, '/catalog').should == {:controller=>'catalog', :action=>'index'}
    params_from(:get, '/catalog/test:3').should == {:controller=>'catalog', :id=>"test:3", :action=>'show'}
    params_from(:get, '/catalog/test:3/delete').should == {:controller=>'catalog', :id=>"test:3", :action=>'delete'}
    params_from(:get, '/catalog/test:3/edit').should == {:controller=>'catalog', :id=>"test:3", :action=>'edit'}
  
    catalog_path("test:3").should == '/catalog/test:3'
  end
  
  it "should not choke on objects with periods in ids (ie Fedora system objects)" do    
    pending "this would require a patch to all routes that allows periods in ids. for now, use rake solrizer:fedora:forget_system_objects"
    catalog_path("fedora-system:FedoraObject-3.0").should == '/catalog/fedora-system:FedoraObject-3.0'
    route_for(:controller=>"catalog", :action=>"show", :id=>"fedora-system:FedoraObject-3.0").should == '/catalog/fedora-system:FedoraObject-3.0'
  end
  
  describe "index" do
    describe "access controls" do
      before(:all) do
        @public_only_results = Blacklight.solr.find Hash[:phrases=>{:access_t=>"public"}]
        @private_only_results = Blacklight.solr.find Hash[:phrases=>{:access_t=>"private"}]
      end

      it "should only return public documents if role does not have permissions" do
        pending("FIXME")
        request.env["WEBAUTH_USER"]="Mr. Notallowed"
        get :index
        assigns("response").docs.count.should == @public_only_results.docs.count
      end
      it "should return all documents if role does have permissions" do
        pending("adjusted for superuser, but assertions aren't working as with test above")
        mock_user = mock("User", :login=>"BigWig")
        session[:superuser_mode] = true
        controller.stubs(:current_user).returns(mock_user)
        get :index
        # assigns["response"].docs.should include(@public_only_results.first)
        # assigns["response"].docs.should include(@private_only_results.first)
        assigns["response"].docs.count.should > @public_only_results.docs.count
      end
    end
  end
  
  describe "show" do
    describe "access controls" do
      it "should deny access to documents if role does not have permissions" do
        request.env["WEBAUTH_USER"]="Mr. Notallowed"
        get :show, :id=>"hydrus:admin_class1"
        response.should redirect_to('/')
        flash[:notice].should ==  "You do not have sufficient access privileges to read this document, which has been marked private."
      end
    end
  end
  
  describe "delete" do 
      describe "access controls" do
        it "should deny access to documents if role does not have permissions" do
          request.env["WEBAUTH_USER"]="Mr. Notallowed"
          get :delete, :id=>"hydrus:admin_class1"
          response.should redirect_to(:action => 'show')
          flash[:notice].should == "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
        end
      end
    end
  
  
end