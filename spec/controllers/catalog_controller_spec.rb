require 'spec_helper'

describe CatalogController do
  let(:user) { FactoryGirl.find_or_create(:user) }
  before do
    GenericFile.any_instance.stub(:characterize_if_changed).and_yield
    sign_in user
  end

  describe "#index" do
    before (:all) do
      GenericFile.delete_all
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
         get :index, q: "pdf"
      end
      it "should find records" do
        expect(response).to be_success
        response.should render_template('catalog/index')
        assigns(:document_list).map(&:id).should == [@gf1.id]
        
        assigns(:document_list).count.should eql(1)
        assigns(:document_list).first['desc_metadata__title_tesim'].should == ['Test Document PDF']

      end
    end

    describe "facet search" do
      before do
        # TODO: this is not how a facet query is done.
        get :index, :q=>"{f=desc_metadata__contributor_tesim}Contrib1"
      end
      it "should find facet files" do
        expect(response).to be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
      end
    end

    describe "without search" do
      it "should set featured researcher" do
        get :index
        expect(response).to be_success
        assigns(:featured_researcher).tap do |researcher|
          expect(researcher).to be_kind_of ContentBlock
          expect(researcher.name).to eq 'featured_researcher'
        end
      end

    end
  end
end
