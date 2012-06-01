require 'spec_helper'

describe CatalogController do
  before do
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  after do
    @user.delete
  end
  describe "#index" do
    describe "term search" do
      before do
          xhr :get, :index, :q =>"pdf"        
      end
      it "should find pdf files" do
        response.should be_success
        response.should render_template('catalog/index')        
        assigns(:document_list).count.should eql(1)
        assigns(:document_list)[0].fetch(:generic_file__title_t)[0].should eql('Test Document PDF')
      end
    end
    describe "facet search" do
      before do
          xhr :get, :index, :fq=>"{!raw f=generic_file__contributor_facet}Contrib1"       
      end
      it "should find facet files" do
        response.should be_success
        response.should render_template('catalog/index')        
        assigns(:document_list).count.should eql(4)
      end
    end
  end  

  describe "#recent" do
    before do
      GenericFile.any_instance.expects(:characterize_if_changed).at_least_once.yields
      @gf1 = GenericFile.create(title:'Generic File 1', contributor:'contributor 1', resource_type:'type 1', discover_groups:['public'])
      sleep 1 # make sure next file is not at the same time compare
      @gf2 = GenericFile.create(title:'Generic File 2', contributor:'contributor 2', resource_type:'type 2', discover_groups:['public'])
      sleep 1 # make sure next file is not at the same time compare
      @gf3 = GenericFile.create(title:'Generic File 3', contributor:'contributor 3', resource_type:'type 3', discover_groups:['public'])
      sleep 1 # make sure next file is not at the same time compare
      @gf4 = GenericFile.create(title:'Generic File 4', contributor:'contributor 4', resource_type:'type 4', discover_groups:['public'])
      xhr :get, :recent
    end
    
    after do
      @gf1.delete
      @gf2.delete
      @gf3.delete
      @gf4.delete
    end 
    
    it "should find my 4 files" do
      response.should be_success
      response.should render_template('catalog/recent')        
      assigns(:recent_documents).count.should eql(4)
      # the order is reversed since the first in should be the last out in descending time order
      assigns(:recent_documents).each {|doc| logger.info doc.fetch(:generic_file__title_t)[0]}
      lgf4 = assigns(:recent_documents)[0]
      lgf3 = assigns(:recent_documents)[1]
      lgf2 = assigns(:recent_documents)[2]
      lgf1 = assigns(:recent_documents)[3]
      lgf4.fetch(:generic_file__title_t)[0].should eql(@gf4.title[0])
      lgf4.fetch(:generic_file__contributor_t)[0].should eql(@gf4.contributor[0])
      lgf4.fetch(:generic_file__resource_type_t)[0].should eql(@gf4.resource_type[0])
      lgf1.fetch(:generic_file__title_t)[0].should eql(@gf1.title[0])
      lgf1.fetch(:generic_file__contributor_t)[0].should eql(@gf1.contributor[0])
      lgf1.fetch(:generic_file__resource_type_t)[0].should eql(@gf1.resource_type[0])
    end
  end
end
