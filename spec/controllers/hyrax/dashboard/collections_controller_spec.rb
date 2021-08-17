# frozen_string_literal: true
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Dashboard::CollectionsController, :clean_repo do
  routes { Hyrax::Engine.routes }
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:collection_type_gid) { FactoryBot.create(:user_collection_type).to_global_id.to_s }

  let(:collection) do
    create(:public_collection_lw, title: ["My collection"],
                                  description: ["My incredibly detailed description of the collection"],
                                  user: user)
  end

  let(:asset1)         { create(:work, title: ["First of the Assets"], user: user) }
  let(:asset2)         { create(:work, title: ["Second of the Assets"], user: user) }
  let(:asset3)         { create(:work, title: ["Third of the Assets"], user: user) }
  let(:asset4)         { build(:collection_lw, title: ["First subcollection"], user: user) }
  let(:asset5)         { build(:collection_lw, title: ["Second subcollection"], user: user) }
  let(:unowned_asset)  { create(:work, user: other) }

  let(:collection_attrs) do
    { title: ['My First Collection'], description: ["The Description\r\n\r\nand more"], collection_type_gid: [collection_type_gid] }
  end

  describe '#new' do
    before { sign_in user }

    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before { sign_in user }

    # rubocop:disable RSpec/ExampleLength
    it "creates a Collection" do
      expect do
        post :create, params: {
          collection: collection_attrs.merge(
            visibility: 'open',
            # TODO: Tests with old approach to sharing a collection which is deprecated and
            # will be removed in 3.0.  New approach creates a PermissionTemplate with
            # source_id = the collection's id.
            permissions_attributes: [{ type: 'person',
                                       name: 'archivist1',
                                       access: 'edit' }]
          )
        }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].visibility).to eq 'open'
      expect(assigns[:collection].edit_users).to contain_exactly "archivist1", user.email
      expect(flash[:notice]).to eq "Collection was successfully created."
    end

    it "removes blank strings from params before creating Collection" do
      expect do
        post :create, params: {
          collection: collection_attrs.merge(creator: [''])
        }
      end.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq ["My First Collection"]
      expect(assigns[:collection].creator).to eq []
    end

    context "with files I can access" do
      it "creates a collection using only the accessible files" do
        expect do
          post :create, params: {
            collection: collection_attrs,
            batch_document_ids: [asset1.id, asset2.id, unowned_asset.id]
          }
        end.to change { Collection.count }.by(1)
        collection = assigns(:collection)
        expect(collection.member_objects).to match_array [asset1, asset2]
      end

      it "adds docs to the collection and adds the collection id to the documents in the collection" do
        post :create, params: {
          batch_document_ids: [asset1.id, unowned_asset.id],
          collection: collection_attrs
        }

        expect(assigns[:collection].member_objects).to eq [asset1]
        asset_results = Hyrax::SolrService.get(fq: ["id:\"#{asset1.id}\""], fl: ['id', "collection_tesim"])
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset1.id
      end
    end

    context 'when setting collection type' do
      let(:collection_type) { create(:collection_type) }

      it "creates a Collection of default type when type is nil" do
        expect do
          post :create, params: {
            collection: collection_attrs
          }
        end.to change { Collection.count }.by(1)
        expect(assigns[:collection].collection_type.machine_id).to eq Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
      end

      it "creates a Collection of specified type" do
        expect do
          post :create, params: {
            collection: collection_attrs, collection_type_gid: collection_type.to_global_id.to_s
          }
        end.to change { Collection.count }.by(1)

        expect(assigns[:collection].collection_type_gid).to eq collection_type.to_global_id.to_s
      end
    end

    context "when params includes parent_id" do
      let(:parent_collection) { create(:collection_lw, title: ['Parent']) }

      it "creates a collection as a subcollection of parent" do
        parent_collection
        expect do
          post :create, params: {
            collection: collection_attrs, parent_id: parent_collection.id
          }
        end.to change { Collection.count }.by(1)
        expect(assigns[:collection].reload.member_of_collections).to eq [parent_collection]
      end
    end

    context "when create fails" do
      let(:collection) { Collection.new }

      before do
        allow(controller).to receive(:authorize!)
        allow(Collection).to receive(:new).and_return(collection)
        allow(collection).to receive(:save).and_return(false)
      end

      it "renders the form again" do
        post :create, params: { collection: collection_attrs }
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#update" do
    let(:listener) { Hyrax::Specs::SpyListener.new }

    before do
      Hyrax.publisher.subscribe(listener)
      sign_in user
    end

    after { Hyrax.publisher.unsubscribe(listener) }

    context 'collection members' do
      before do
        [asset1, asset2].each do |asset|
          asset.member_of_collections << collection
          asset.save!
        end
      end

      it "adds members to the collection from edit form" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset3.id],
                                 stay_on_edit: true }
        end.to change { collection.reload.member_objects.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.edit_dashboard_collection_path(collection, locale: 'en')
        expect(assigns[:collection].member_objects).to match_array [asset1, asset2, asset3]
      end

      it "adds members to the collection from other than the edit form" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'add' },
                                 batch_document_ids: [asset3.id] }
        end.to change { collection.reload.member_objects.size }.by(1)
        expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        expect(assigns[:collection].member_objects).to match_array [asset1, asset2, asset3]
      end

      it "removes members from the collection" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'remove' },
                                 batch_document_ids: [asset2] }
        end.to change { asset2.reload.member_of_collections.size }.by(-1)
        expect(assigns[:collection].member_objects).to match_array [asset1]
      end

      it "publishes object.metadata.updated for removed objects" do
        expect do
          put :update, params: { id: collection,
                                 collection: { members: 'remove' },
                                 batch_document_ids: [asset2] }
        end
          .to change { listener.object_metadata_updated&.payload }
          .to match(object: have_attributes(id: asset2.id), user: user)
      end
    end

    context 'when moving members between collections' do
      let(:asset1) { create(:generic_work, user: user) }
      let(:asset2) { create(:generic_work, user: user) }
      let(:asset3) { create(:generic_work, user: user) }
      let(:collection2) { create(:collection_lw, title: ['Some Collection'], user: user) }

      before do
        [asset1, asset2, asset3].each do |asset|
          asset.member_of_collections << collection
          asset.save
        end
      end

      it 'moves the members' do
        put :update,
            params: {
              id: collection,
              collection: { members: 'move' },
              destination_collection_id: collection2,
              batch_document_ids: [asset2, asset3]
            }
        expect(collection.reload.member_objects).to eq [asset1]
        expect(collection2.reload.member_objects).to match_array [asset2, asset3]
      end
    end

    context "updating a collections metadata" do
      it "saves the metadata" do
        put :update, params: { id: collection, collection: { creator: ['Emily'] } }
        collection.reload
        expect(collection.creator).to eq ['Emily']
        expect(flash[:notice]).to eq "Collection was successfully updated."
      end

      it "removes blank strings from params before updating Collection metadata" do
        put :update, params: {
          id: collection,
          collection: {
            title: ["My Next Collection "],
            creator: [""]
          }
        }
        expect(assigns[:collection].title).to eq ["My Next Collection "]
        expect(assigns[:collection].creator).to eq []
      end
    end

    context "when update fails" do
      let(:collection) { build(:collection_lw, id: '12345') }
      let(:repository) { instance_double(Blacklight::Solr::Repository, search: result) }
      let(:result) { double(documents: [], total: 0) }

      before do
        allow(controller).to receive(:authorize!)
        allow(Collection).to receive(:find).and_return(collection)
        allow(collection).to receive(:update).and_return(false)
        allow(controller).to receive(:repository).and_return(repository)
      end

      it "renders the form again" do
        put :update, params: {
          id: collection,
          collection: collection_attrs
        }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end

    context "updating a collections branding metadata" do
      let(:uploaded) { FactoryBot.create(:uploaded_file) }

      it "saves banner metadata" do
        put :update, params: { id: collection, banner_files: [uploaded.id], collection: { creator: ['Emily'] }, update_collection: true }

        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id, role: "banner")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .to exist
      end

      it "don't save banner metadata" do
        put :update, params: { id: collection, banner_files: [uploaded.id], collection: { creator: ['Emily'] } }
        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id, role: "banner")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .not_to exist
      end

      it "saves logo metadata" do
        put :update, params: { id: collection,
                               logo_files: [uploaded.id],
                               alttext: ["Logo alt Text"],
                               linkurl: ["http://abc.com"],
                               collection: { creator: ['Emily'] },
                               update_collection: true }

        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id, role: "logo", alt_text: "Logo alt Text", target_url: "http://abc.com")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .to exist
      end

      context 'where the linkurl is not a valid http|http link' do
        let(:uploaded) { FactoryBot.create(:uploaded_file) }

        it "does not save linkurl containing html; target_url is empty" do
          put :update, params: { id: collection,
                                 logo_files: [uploaded.id],
                                 alttext: ["Logo alt Text"], linkurl: ["<script>remove_me</script>"],
                                 collection: { creator: ['Emily'] },
                                 update_collection: true }

          expect(
            CollectionBrandingInfo.where(
              collection_id: collection.id,
              target_url: "<script>remove_me</script>"
            ).where("target_url LIKE '%remove_me%)'")
          ).not_to exist
        end

        it "does not save linkurl containing dodgy protocol; target_url is empty" do
          put :update, params: { id: collection,
                                 logo_files: [uploaded.id],
                                 alttext: ["Logo alt Text"],
                                 linkurl: ['javascript:alert("remove_me")'],
                                 collection: { creator: ['Emily'] },
                                 update_collection: true }

          expect(
            CollectionBrandingInfo.where(
              collection_id: collection.id,
              target_url: 'javascript:alert("remove_me")'
            ).where("target_url LIKE '%remove_me%)'")
          ).not_to exist
        end
      end
    end
  end

  describe "#show" do
    context "when signed in" do
      before do
        sign_in user
        [asset1, asset2, asset3, asset4, asset5].each do |asset|
          asset.member_of_collections = [collection]
          asset.save
        end
      end

      it "returns the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), "aria-current" => "page")
        get :show, params: { id: collection }
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
        expect(assigns[:presenter].title).to match_array collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
        expect(assigns[:subcollection_docs].map(&:id)).to match_array [asset4, asset5].map(&:id)
        expect(assigns[:members_count]).to eq(3)
        expect(assigns[:subcollection_count]).to eq(2)
      end

      context "and searching" do
        it "returns some works and collections" do
          # "/dashboard/collections/4m90dv529?utf8=%E2%9C%93&cq=King+Louie&sort="
          get :show, params: { id: collection, cq: "Second" }
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:member_docs].map(&:id)).to match_array [asset2].map(&:id)
          expect(assigns[:subcollection_docs].map(&:id)).to match_array [asset5].map(&:id)
          expect(assigns[:members_count]).to eq(1)
          expect(assigns[:subcollection_count]).to eq(1)
        end
      end

      context 'when the page parameter is passed' do
        it 'loads the collection (paying no attention to the page param)' do
          get :show, params: { id: collection, page: '2' }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of Hyrax::CollectionPresenter
          expect(assigns[:presenter].to_s).to eq 'My collection'
        end
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), "aria-current" => "page")
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), "aria-current" => "page")
          get :show, params: { id: collection }
          expect(response).to be_successful
        end
      end
    end

    context 'with admin user and private collection' do
      let(:collection) do
        create(:private_collection,
               title: ["My collection"],
               description: ["My incredibly detailed description of the collection"],
               user: user)
      end
      let(:admin) { create(:admin) }

      before do
        sign_in admin
        allow(controller.current_ability).to receive(:can?).with(:show, collection).and_return(true)
      end

      it "returns successfully" do
        get :show, params: { id: collection }
        expect(response).to be_successful
      end
    end

    context "when not signed in" do
      it "redirects to sign in page" do
        get :show, params: { id: collection }
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe "#delete" do
    before { sign_in user }
    context "when it succeeds" do
      it "redirects to My Collections" do
        delete :destroy, params: { id: collection }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(flash[:notice]).to eq "Collection was successfully deleted"
      end

      it "returns json" do
        delete :destroy, params: { format: :json, id: collection }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when an error occurs" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Collection).to receive(:destroy).and_return(nil)
      end
      it "renders the edit view" do
        delete :destroy, params: { id: collection }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash[:notice]).to eq "Collection could not be deleted"
      end

      it "returns json" do
        delete :destroy, params: { format: :json, id: collection }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#edit" do
    before { sign_in user }

    it "is successful" do
      get :edit, params: { id: collection }
      expect(response).to be_successful
      expect(assigns[:form]).to be_instance_of Hyrax::Forms::CollectionForm
      expect(flash[:notice]).to be_nil
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.collection.edit_view"), collection_path(collection.id, locale: 'en'), "aria-current" => "page")
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.collection.edit_view"), collection_path(collection.id, locale: 'en'), "aria-current" => "page")
        get :edit, params: { id: collection }
        expect(response).to be_successful
      end
    end
  end

  describe "#files" do
    before { sign_in user }

    it 'shows a list of member files' do
      get :files, params: { id: collection }, format: :json
      expect(response).to be_successful
    end
  end
end
