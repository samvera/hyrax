require 'spec_helper'

describe CatalogController, :type => :controller do
  routes { Rails.application.class.routes }

  let(:user) { FactoryGirl.find_or_create(:jill) }

  before do
    sign_in user
  end

  describe "#index" do

    let!(:rocks) {
      GenericWork.new(id: 'rock123').tap do |work|
        work.title = ['Rock Documents']
        work.read_groups = ['public']
        work.apply_depositor_metadata('mjg36')
      end
    }

    let!(:clouds) {
      GenericWork.new(id: 'cloud123').tap do |work|
        work.title = ['Cloud Documents']
        work.read_groups = ['public']
        work.apply_depositor_metadata('mjg36')
        work.contributor = ['frodo']
      end
    }

    before do
      objects.each { |obj| ActiveFedora::SolrService.add(obj.to_solr) }
      ActiveFedora::SolrService.commit
    end
    context 'with a non-work file' do
      let!(:file) {
        GenericFile.new(id: 'file123').tap do |file|
        file.title('File about Rocks')
        file.filename = ['test.pdf']
        file.read_groups = ['public']
        file.apply_depositor_metadata('mjg36')
        end
      }
      let (:objects) { [file, rocks, clouds]}

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
        Collection.new(id: 'collection1', title: 'my collection', tag: ['rocks'], read_groups: ['public']).tap do |c|
           c.apply_depositor_metadata('mjg36')
        end
      }
      let (:objects) { [collection, rocks, clouds]}

      it 'finds collections' do
        xhr :get, :index, q: 'rocks'
        expect(response).to be_success
        doc_list = assigns(:document_list)
        expect(doc_list.map(&:id)).to match_array [collection.id, rocks.id]
      end
    end

    describe 'term search' do
      let (:objects) { [rocks, clouds]}
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
      let (:objects) { [rocks, clouds]}
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
      let (:objects) { [rocks, clouds]}
      it 'finds matching records' do
        get :index, q: 'full_textfull_text'
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to eq [clouds.id]
      end
    end

    context 'works by file metadata' do
      let (:objects) { [] } # Can't use this shorthand due to the complexity of relationships between GenericFiles and GenericWorks
      # Building the objects in a before(:all) to minimize the overhead of creating and destroying all these objects in Fedora three times
      before(:all) do
        user =  FactoryGirl.find_or_create(:jill)
        work1 = FactoryGirl.create(:generic_work, title: ["me too"], read_groups: ['public'], user:user)
        work2 = FactoryGirl.create(:generic_work, title: ["find me"], read_groups: ['public'], user:user)
        file1 = GenericFile.new.tap do |f|
            f.title= ['find me']
            f.apply_depositor_metadata(user)
            f.save!
            Hydra::Works::AddGenericFileToGenericWork.call(work1, f)
          end
        file2 = GenericFile.new.tap do |f|
            f.title= ['other file']
            f.apply_depositor_metadata(user)
            f.save!
            Hydra::Works::AddGenericFileToGenericWork.call(work1, f)
        end
        @user = user
        @work1 = work1
        @work2 = work2
        @file1 = file1
        @file2 = file2
      end

      it "finds work and work that contains file with title" do
        get :index, q: 'find me'
        expect(assigns(:document_list).count).to eq 2
        expect(assigns(:document_list).map(&:id)).to include(@work1.id, @work2.id)
      end

      it "finds work that contains file with title" do
        get :index, q: 'other file'
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to include(@work1.id)
      end

      it "finds work with title" do
        get :index, q: 'me too'
        expect(assigns(:document_list).count).to eq 1
        expect(assigns(:document_list).map(&:id)).to include(@work1.id)
      end

    end

  end  # describe "#index"

end
