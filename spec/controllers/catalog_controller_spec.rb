require 'spec_helper'

describe CatalogController do
  before do
    GenericFile.any_instance.stub(:characterize_if_changed).and_yield
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  after do
    @user.delete
  end
  describe "#index" do
    before (:all) do
      GenericFile.find_each { |f| f.delete }
      @gf1 =  GenericFile.new(title:'Test Document PDF', filename:'test.pdf', read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save
      @gf2 =  GenericFile.new(title:'Test 2 Document', filename:'test2.doc', contributor:'Contrib1', read_groups:['public'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save
    end
    after (:all) do
      @gf1.delete
      @gf2.delete
    end
    describe "term search" do
      before do
         xhr :get, :index, :q =>"pdf"
      end
      it "should find pdf files" do
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).map(&:id).should == [@gf1.id]
        
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).first['desc_metadata__title_tesim'].should == ['Test Document PDF']
      end
    end
    describe "facet search" do
      before do
        # TODO: this is not how a facet query is done.
        xhr :get, :index, :q=>"{f=desc_metadata__contributor_tesim}Contrib1"
      end
      it "should find facet files" do
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
      end
    end
  end

  describe "#recent" do
    before do
      @gf1 = GenericFile.new(title:'Generic File 1', contributor:'contributor 1', resource_type:'type 1', read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save!
      sleep 1 # make sure next file is not at the same time compare
      @gf2 = GenericFile.new(title:'Generic File 2', contributor:'contributor 2', resource_type:'type 2', read_groups:['public'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save!
      sleep 1 # make sure next file is not at the same time compare
      @gf3 = GenericFile.new(title:'Generic File 3', contributor:'contributor 3', resource_type:'type 3', read_groups:['public'])
      @gf3.apply_depositor_metadata('mjg36')
      @gf3.save!
      sleep 1 # make sure next file is not at the same time compare
      @gf4 = GenericFile.new(title:'Generic File 4', contributor:'contributor 4', resource_type:'type 4', read_groups:['public'])
      @gf4.apply_depositor_metadata('mjg36')
      @gf4.save!
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
      #assigns(:recent_documents).each {|doc| logger.info doc.fetch(:desc_metadata__title_t)[0]}
      lgf1 = assigns(:recent_documents)[0]
      lgf4 = assigns(:recent_documents)[3]
      lgf4['desc_metadata__title_tesim'].should == ['Generic File 4']
      lgf4['desc_metadata__contributor_tesim'].should == ['contributor 4']
      lgf4['desc_metadata__resource_type_tesim'].should == ['type 4']

      lgf1['desc_metadata__title_tesim'].should == ['Generic File 1']
      lgf1['desc_metadata__contributor_tesim'].should == ['contributor 1']
      lgf1['desc_metadata__resource_type_tesim'].should == ['type 1']
    end
  end
end
