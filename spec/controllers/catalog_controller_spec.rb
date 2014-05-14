require 'spec_helper'

describe CatalogController do
  routes { Rails.application.class.routes }

  let(:user) { @user }

  before do
    GenericFile.any_instance.stub(:characterize_if_changed).and_yield
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
      context "searching everything" do
        it "should find records" do
          get :index, q: "pdf", owner: 'all'
          expect(response).to be_success
          response.should render_template('catalog/index')
          assigns(:document_list).map(&:id).should == [@gf1.id]
          assigns(:document_list).count.should eql(1)
          assigns(:document_list).first['desc_metadata__title_tesim'].should == ['Test Document PDF']
        end
      end
      context "searching only documents editable to me" do
        it "should only have records I can edit" do
          get :index, q: "", owner: 'mine'
          assigns(:document_list).map(&:id).should == [@editable_file.id]
          expect(response).to be_success
        end
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
  end
end
