# frozen_string_literal: true
RSpec.describe CatalogController, type: :controller do
  routes { Rails.application.class.routes }

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "#index" do
    let(:rocks) do
      GenericWork.new(id: 'rock123', title: ['Rock Documents'], read_groups: ['public'])
    end

    let(:clouds) do
      GenericWork.new(id: 'cloud123', title: ['Cloud Documents'], read_groups: ['public'],
                      contributor: ['frodo'])
    end

    before do
      objects.each { |obj| Hyrax::SolrService.add(obj.to_solr) }
      Hyrax::SolrService.commit
    end

    context 'with a non-work file' do
      let(:file) { FileSet.new(id: 'file123') }
      let(:objects) { [file, rocks, clouds] }

      it 'finds works, not files' do
        get :index
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')

        ids = assigns(:response).documents.map(&:id)
        expect(ids).to include rocks.id
        expect(ids).to include clouds.id
        expect(ids).not_to include file.id
      end
    end

    context 'with collections' do
      let(:collection) { create(:public_collection_lw, keyword: ['rocks']) }
      let(:objects) { [collection, rocks, clouds] }

      it 'finds collections' do
        get :index, params: { q: 'rocks' }, xhr: true
        expect(response).to be_successful
        doc_list = assigns(:response).documents
        expect(doc_list.map(&:id)).to match_array [collection.id, rocks.id]
      end
    end

    describe 'term search', :clean_repo do
      let(:objects) { [rocks, clouds] }

      it 'finds works with the given search term' do
        get :index, params: { q: 'rocks', owner: 'all' }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(rocks.id)
      end
    end

    describe 'facet search' do
      let(:objects) { [rocks, clouds] }

      before do
        get :index, params: { 'f' => { 'contributor_sim' => ['frodo'] } }
      end

      it 'finds faceted works' do
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(clouds.id)
      end
    end

    describe 'full-text search', skip: 'Will GenericWorks have a full_text search?' do
      let(:objects) { [rocks, clouds] }

      it 'finds matching records' do
        get :index, params: { q: 'full_textfull_text' }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(clouds.id)
      end
    end

    context 'works by file metadata' do
      let(:objects) do
        [double(to_solr: file1), double(to_solr: file2),
         double(to_solr: work1), double(to_solr: work2)]
      end

      let(:work1) do
        { has_model_ssim: ["GenericWork"], id: "ff365c76z", title_tesim: ["me too"],
          file_set_ids_ssim: ["ff365c78h", "ff365c79s"],
          read_access_group_ssim: ["public"], edit_access_person_ssim: ["user1@example.com"] }
      end

      let(:work2) do
        { has_model_ssim: ["GenericWork"], id: "ff365c777", title_tesim: ["find me"],
          file_set_ids_ssim: [],
          read_access_group_ssim: ["public"], edit_access_person_ssim: ["user2@example.com"] }
      end

      let(:file1) do
        { has_model_ssim: ["FileSet"], id: "ff365c78h", title_tesim: ["find me"],
          file_set_ids_ssim: [],
          edit_access_person_ssim: [user.user_key] }
      end

      let(:file2) do
        { has_model_ssim: ["FileSet"], id: "ff365c79s", title_tesim: ["other file"],
          file_set_ids_ssim: [],
          edit_access_person_ssim: [user.user_key] }
      end

      it "finds a work and a work that contains a file set with a matching title" do
        get :index, params: { q: 'find me', search_field: 'all_fields' }
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id], work2[:id])
      end

      it "finds a work that contains a file set with a matching title" do
        get :index, params: { q: 'other file', search_field: 'all_fields' }
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id])
      end

      it "finds a work with a matching title" do
        get :index, params: { q: 'me too', search_field: 'all_fields' }
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id])
      end
    end
  end
end
