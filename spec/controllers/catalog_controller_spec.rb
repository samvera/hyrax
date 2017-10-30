RSpec.describe CatalogController, type: :controller do
  routes { Rails.application.class.routes }

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "#index" do
    let(:rocks) do
      create_for_repository(:work, id: 'rock123', title: ['Rock Documents'], read_groups: ['public'])
    end

    let(:clouds) do
      create_for_repository(:work, id: 'cloud123', title: ['Cloud Documents'], read_groups: ['public'],
                                   contributor: ['frodo'])
    end

    context 'with a non-work file' do
      let(:file) { create_for_repository(:file_set, id: 'file123') }

      # Create fixtures
      before { [file, rocks, clouds] }

      it 'finds works, not files' do
        get :index
        expect(response).to be_success
        expect(response).to render_template('catalog/index')

        ids = assigns(:document_list).map(&:id)
        expect(ids).to include rocks.id.to_s
        expect(ids).to include clouds.id.to_s
        expect(ids).not_to include file.id.to_s
      end
    end

    context 'with collections' do
      let(:collection) { create_for_repository(:public_collection, keyword: ['rocks']) }

      # Create fixtures
      before { [collection, rocks, clouds] }

      it 'finds collections' do
        get :index, params: { q: 'rocks' }, xhr: true
        expect(response).to be_success
        doc_list = assigns(:document_list)
        expect(doc_list.map(&:id)).to match_array [collection, rocks].map(&:id).map(&:to_s)
      end
    end

    describe 'term search', :clean_repo do
      # Create fixtures
      before { [rocks, clouds] }

      it 'finds works with the given search term' do
        get :index, params: { q: 'rocks', owner: 'all' }
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).map(&:id)).to contain_exactly(rocks.id.to_s)
      end
    end

    describe 'facet search' do
      before do
        # Create fixtures
        rocks
        clouds
        get :index, params: { 'f' => { 'contributor_tesim' => ['frodo'] } }
      end

      it 'finds faceted works' do
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).map(&:id)).to contain_exactly(clouds.id.to_s)
      end
    end

    describe 'full-text search', skip: 'Will GenericWorks have a full_text search?' do
      # Create fixtures
      before { [rocks, clouds] }

      it 'finds matching records' do
        get :index, params: { q: 'full_textfull_text' }
        expect(response).to be_success
        expect(response).to render_template('catalog/index')
        expect(assigns(:document_list).map(&:id)).to contain_exactly(clouds.id)
      end
    end

    context 'works by file metadata' do
      let!(:work1) do
        create_for_repository(:work, :public, title: ["me too"], member_ids: [file1.id.to_s, file2.id.to_s])
      end

      let!(:work2) do
        create_for_repository(:work, :public, title: ["find me"])
      end

      let(:file1) do
        create_for_repository(:file_set, user: user, title: ["find me"])
      end

      let(:file2) do
        create_for_repository(:file_set, user: user, title: ["other file"])
      end

      it "finds a work and a work that contains a file set with a matching title" do
        get :index, params: { q: 'find me', search_field: 'all_fields' }
        expect(assigns(:document_list).map(&:id)).to match_array([work1, work2].map(&:id).map(&:to_s))
      end

      it "finds a work that contains a file set with a matching title" do
        get :index, params: { q: 'other file', search_field: 'all_fields' }
        expect(assigns(:document_list).map(&:id)).to contain_exactly(work1.id.to_s)
      end

      it "finds a work with a matching title" do
        get :index, params: { q: 'me too', search_field: 'all_fields' }
        expect(assigns(:document_list).map(&:id)).to contain_exactly(work1.id.to_s)
      end
    end
  end # describe "#index"
end
