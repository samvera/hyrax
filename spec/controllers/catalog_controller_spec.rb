require 'spec_helper'

describe CatalogController, :type => :controller do
  routes { Rails.application.class.routes }

  let(:user) { FactoryGirl.find_or_create(:jill) }

  before do
    sign_in user
  end

  describe "#index" do
    before do
      @gf1 = GenericFile.new(title: ['Test Document PDF'], filename: ['test.pdf'], tag: ['rocks'], read_groups: ['public']).tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.save!
      end

      @gf2 = GenericFile.new(title: ['Test 2 Document'], filename: ['test2.doc'], tag: ['clouds'], contributor: ['Contrib1'],
                             read_groups: ['public']).tap do |f|
        f.apply_depositor_metadata('mjg36')
        f.full_text.content = 'full_textfull_text'
        f.save!
      end

      @editable_file = GenericFile.new.tap do |f|
        f.apply_depositor_metadata(user.user_key)
        f.save!
      end
    end

    describe 'full-text search' do
      it 'finds records' do
        get :index, q: 'full_textfull_text'
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq [@gf2.id]
      end
    end

    describe "term search" do
      it "should find records" do
        get :index, q: "pdf", owner: 'all'
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).map(&:id)).to eq [@gf1.id]
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).first[Solrizer.solr_name("title")]).to eq ['Test Document PDF']
      end
    end

    describe "facet search" do
      before do
        # TODO: this is not how a facet query is done.
        get :index, q: "{f=contributor_tesim}Contrib1"
      end
      it "should find facet files" do
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
      end
    end

    context "with collections" do
      before do
       @collection = Collection.new(title:"my collection", tag: ['rocks'], read_groups: ['public']).tap do |c|
         c.apply_depositor_metadata('mjg36')
         c.save!
       end
      end

      it "finds collections and files" do
        xhr :get, :index, q: "rocks"
        expect(response).to be_success
        doc_list = assigns(:document_list)
        expect(doc_list.map(&:id)).to match_array [@collection.id, @gf1.id]
      end

    end

  end
end
