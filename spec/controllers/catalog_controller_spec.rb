# frozen_string_literal: true
RSpec.describe CatalogController, :clean_repo, type: :controller do
  routes { Rails.application.class.routes }

  let(:user) { create(:user) }

  before { sign_in user }

  describe "#index" do
    let(:rocks) { valkyrie_create(:monograph, title: ['Rock Documents'], read_groups: ['public']) }
    let(:clouds) { valkyrie_create(:monograph, title: ['Cloud Documents'], read_groups: ['public']) }

    before do
      objects
      clouds.contributor = ['frodo']
      Hyrax.persister.save(resource: clouds)
      Hyrax.index_adapter.save(resource: clouds)
    end

    context 'with a non-work file' do
      let(:file) { valkyrie_create(:hyrax_file_set) }
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
      let(:collection) { valkyrie_create(:hyrax_collection, :public, title: ['rocks']) }
      let(:objects) { [collection, rocks, clouds] }

      it 'finds collections' do
        get :index, params: { q: 'rocks', search_field: 'all_fields' }, xhr: true
        expect(response).to be_successful
        doc_list = assigns(:response).documents
        expect(doc_list.map(&:id)).to match_array [collection.id, rocks.id]
      end
    end

    describe 'term search' do
      # An attached fileset needs to be present in the index to trigger the
      # {!join} in Hyrax::CatalogSearchBuilder#join_for_works_from_files
      # and ensure it does not interfere with query results
      let(:unrelated) { valkyrie_create(:monograph, :with_one_file_set, title: ['Unrelated'], read_groups: ['public']) }
      let(:objects) { [rocks, clouds, unrelated] }

      it 'finds works with the given search term' do
        get :index, params: { q: 'rocks', search_field: 'all_fields' }
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
        get :index, params: { q: 'full_textfull_text', search_field: 'all_fields' }
        expect(response).to be_successful
        expect(response).to render_template('catalog/index')
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(clouds.id)
      end
    end

    context 'works by file metadata (ActiveFedora)', :active_fedora do
      let(:objects) do
        [double(to_solr: file1), double(to_solr: file2),
         double(to_solr: work1), double(to_solr: work2)]
      end
      let(:work1) do
        { has_model_ssim: ["GenericWork"], id: "ff365c76z", title_tesim: ["me too"],
          member_ids_ssim: ["ff365c78h", "ff365c79s"], read_access_group_ssim: ["public"],
          edit_access_person_ssim: ["user1@example.com"] }
      end
      let(:work2) do
        { has_model_ssim: ["GenericWork"], id: "ff365c777", title_tesim: ["find me"],
          member_ids_ssim: [], read_access_group_ssim: ["public"], edit_access_person_ssim: ["user2@example.com"] }
      end
      let(:file1) do
        { has_model_ssim: ["FileSet"], id: "ff365c78h", title_tesim: ["find me"],
          member_ids_ssim: [], edit_access_person_ssim: [user.user_key] }
      end
      let(:file2) do
        { has_model_ssim: ["FileSet"], id: "ff365c79s", title_tesim: ["other file"],
          member_ids_ssim: [], edit_access_person_ssim: [user.user_key] }
      end

      before do
        objects.each { |obj| Hyrax::SolrService.add(obj.to_solr) }
        Hyrax::SolrService.commit
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

    context 'works by file metadata (Valkyrie)' do
      let(:objects) { [file1, file2, work1, work2] }
      let(:other_user) { create(:user) }
      let(:work1) do
        valkyrie_create(:monograph, title: ['me too'], read_groups: ['public'], members: [file1, file2], edit_users: [user.user_key])
      end
      let(:work2) do
        valkyrie_create(:monograph, title: ['find me'], read_groups: ['public'], edit_users: [other_user.user_key])
      end
      let(:file1) do
        valkyrie_create(:hyrax_file_set, title: ['find me'], edit_users: [user.user_key])
      end
      let(:file2) do
        valkyrie_create(:hyrax_file_set, title: ['other file'], edit_users: [user.user_key])
      end

      # NOTE: The old expected behavior was "finds a work and a work that contains a file set with a matching title".
      #   This is no longer the case in a Valkyrie environment. A work's child file set's metadata is no longer passed in
      #   to the work's SolrDocument. The only references to the containing file sets are their ids.
      it "finds a work and a work that contains a file set with a matching title" do
        get :index, params: { q: 'find me', search_field: 'all_fields' }
        expect(assigns(:response).documents.map(&:id)).to contain_exactly(work1[:id], work2[:id])
      end

      # NOTE: The same logic in the above comment applies here.
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
