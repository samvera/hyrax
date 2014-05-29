require 'spec_helper'

describe CatalogController do
  routes { Rails.application.class.routes }

  let(:user) { @user }

  before do
    sign_in user
  end

  describe "#index" do
    before (:all) do
      @user = FactoryGirl.find_or_create(:jill)
      GenericFile.delete_all
      @gf1 =  GenericFile.new(title:'Test Document PDF', filename:'test.pdf', tag:'rocks', read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save

      @gf2 =  GenericFile.new(title:'Test 2 Document', filename:'test2.doc', tag:'clouds', contributor:'Contrib1', read_groups:['public'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save

      @editable_file = GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(@user.user_key)
        gf.save!
      end
    end

    after (:all) do
      @gf1.delete
      @gf2.delete
    end

    describe "term search" do
      it "should find records" do
        get :index, q: "pdf", owner: 'all'
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
        get :index, q: "{f=desc_metadata__contributor_tesim}Contrib1"
      end
      it "should find facet files" do
        expect(response).to be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
      end
    end

    context "with collections" do
      before do
       @collection = Collection.new(title:"my collection", tag: 'rocks').tap do |c|
         c.apply_depositor_metadata('mjg36')
         c.save!
       end
      end

      after do
        @collection.destroy
      end

      it "finds collections and files" do
        xhr :get, :index, q:"rocks"
        expect(response).to be_success
        doc_list = assigns(:document_list)
        expect(doc_list.map(&:id)).to match_array [@collection.id, @gf1.id]
      end

    end

  end
end
