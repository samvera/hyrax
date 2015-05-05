require 'spec_helper'

describe CatalogController, :type => :controller do
  routes { Rails.application.class.routes }

  let(:user) { FactoryGirl.find_or_create(:jill) }

  before do
    sign_in user
  end

  describe "#index" do

    let!(:rocks) {
      Sufia::Works::GenericWork.new.tap do |work|
        work.title = ['Rock Documents']
        work.read_groups = ['public']
        work.apply_depositor_metadata('mjg36')
        work.save!
      end
    }

    let!(:clouds) {
      Sufia::Works::GenericWork.new.tap do |work|
        work.title = ['Cloud Documents']
        work.read_groups = ['public']
        work.apply_depositor_metadata('mjg36')
        work.contributor = ['frodo']
        work.save!
      end
    }

    context 'with a non-work file' do
      let!(:file) {
        GenericFile.new.tap do |file|
        file.title('File about Rocks')
        file.filename = ['test.pdf']
        file.read_groups = ['public']
        file.apply_depositor_metadata('mjg36')
        file.save!
        end
      }

      it 'finds works, not files' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('catalog/index')

        ids = assigns(:document_list).map(&:id)
        expect(ids).to     include rocks.id
        expect(ids).to     include clouds.id
        expect(ids).not_to include file.id
      end
    end

    context 'with collections' do
      let!(:collection) {
        Collection.new(title: 'my collection', tag: ['rocks'], read_groups: ['public']).tap do |c|
           c.apply_depositor_metadata('mjg36')
           c.save!
        end
      }

      it 'finds collections' do
        xhr :get, :index, q: 'rocks'
        expect(response).to be_success
        doc_list = assigns(:document_list)
        expect(doc_list.map(&:id)).to match_array [collection.id, rocks.id]
      end
    end

    describe 'term search' do
      it 'finds works with the given search term' do
        get :index, q: 'rocks', owner: 'all'
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq [rocks.id]
        expect(assigns(:document_list).first[Solrizer.solr_name("title")]).to eq ['Rock Documents']
      end
    end

    describe 'facet search' do
      before do
        get :index, {'f' => {'contributor_tesim' => ['frodo']}}
      end

      it 'finds faceted works' do
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq [clouds.id]
      end
    end

    describe 'full-text search', skip: 'Will GenericWorks have a full_text search?' do
      it 'finds matching records' do
        get :index, q: 'full_textfull_text'
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq [clouds.id]
      end
    end

  end  # describe "#index"

end
