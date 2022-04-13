# frozen_string_literal: true
require 'hyrax/specs/spy_listener'
##
# Test the Hyrax::Dashboard::CollectionsController with Hyrax::PcdmCollection,
# which tests handling of Valkyrie::Resource collections.
#
# @note These are the same tests run in `spec/controllers/dashboard/collections_controller_spec.rb`
#       which runs the tests based on `Hyrax.config.collection_model`.  At the time of writing
#       that class is written from the perspective of an ActiveFedora::Base collection.
# @see spec/controllers/dashboard/collections_controller_spec.rb
#
RSpec.describe Hyrax::Dashboard::CollectionsController, type: :controller, clean_repo: true do
  routes { Hyrax::Engine.routes }

  before { allow(Hyrax.config).to receive(:collection_model).and_return('Hyrax::PcdmCollection') }
  let(:collection_type_gid) { FactoryBot.create(:user_collection_type).to_global_id.to_s }
  let(:queries) { Hyrax.custom_queries }
  let(:user) { FactoryBot.create(:user) }

  let(:asset1) { FactoryBot.valkyrie_create(:monograph, title: ["First of the Assets"], edit_users: [user]) }
  let(:asset2) { FactoryBot.valkyrie_create(:monograph, title: ["Second of the Assets"], edit_users: [user]) }
  let(:asset3) { FactoryBot.valkyrie_create(:monograph, title: ["Third of the Assets"], edit_users: [user]) }
  let(:asset4) { FactoryBot.valkyrie_create(:hyrax_collection, title: ["First subcollection"], edit_users: [user]) }
  let(:asset5) { FactoryBot.valkyrie_create(:hyrax_collection, title: ["Second subcollection"], edit_users: [user]) }
  let(:unowned_asset) { FactoryBot.valkyrie_create(:monograph) }

  let(:collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               :public,
                               title: ["My collection"],
                               depositor: user.user_key,
                               edit_users: [user])
  end

  let(:collection_attrs) do
    { title: ['My First Collection'],
      description: ["The Description\r\n\r\nand more"] }
  end

  describe '#new' do
    before { sign_in user }

    it 'assigns @collection' do
      get :new

      expect(assigns(:collection)).to be_kind_of(Hyrax.config.collection_class)
    end
  end

  describe '#create' do
    before { sign_in user }

    it "removes blank strings from params before creating Collection" do
      pending 'creation of a collection resource that includes basic metadata'
      expect { post :create, params: { collection: collection_attrs.merge(creator: ['']) } }
        .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
        .by(1)

      expect(assigns[:collection].title).to eq ["My First Collection"]
      expect(assigns[:collection].creator).to eq []
    end

    it "sets current user as the depositor" do
      expect { post :create, params: { collection: collection_attrs } }
        .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
        .by(1)

      expect(assigns[:collection].depositor).to eq user.user_key
    end

    context "with files I can access" do
      it "creates a collection using only the accessible files" do
        parameters = { collection: collection_attrs,
                       batch_document_ids: [asset1.id, asset2.id, unowned_asset.id] }

        expect { post :create, params: parameters }
          .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
          .by(1)

        collection = Hyrax.query_service.find_by(id: assigns[:collection].id)
        expect(queries.find_members_of(collection: collection).map(&:id))
          .to contain_exactly(asset1.id, asset2.id)
      end

      it "adds docs to the collection and adds the collection id to the documents in the collection" do
        post :create, params: { batch_document_ids: [asset1.id, unowned_asset.id],
                                collection: collection_attrs }

        collection = Hyrax.query_service.find_by(id: assigns[:collection].id)
        expect(queries.find_members_of(collection: collection).map(&:id))
          .to contain_exactly(asset1.id)

        asset_results = Hyrax::SolrService.get(fq: ["id:\"#{asset1.id}\""], fl: ['id', "collection_tesim"])
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset1.id
      end
    end

    context 'when setting collection type' do
      let(:user_collection_type) { FactoryBot.create(:user_collection_type) }
      let!(:user_collection_type_gid) { user_collection_type.to_global_id.to_s }

      context 'and collection type is not passed in' do
        let(:collection_type_gid) { user_collection_type_gid }

        it 'assigns the default User Collection' do
          expect { post :create, params: { collection: collection_attrs } }
            .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
            .by(1)

          type = GlobalID::Locator.locate(assigns[:collection].collection_type_gid)
          expect(type.to_global_id.to_s).to eq user_collection_type_gid
        end
      end

      context 'and collection type is passed in' do
        let(:collection_type) { FactoryBot.create(:collection_type, creator_user: user) }
        let(:collection_type_gid) { collection_type.to_global_id.to_s }
        let(:parameters) do
          { collection: collection_attrs,
            collection_type_gid: collection_type_gid }
        end

        it "creates a Collection of specified type" do
          expect { post :create, params: parameters }
            .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
            .by(1)

          type = GlobalID::Locator.locate(assigns[:collection].collection_type_gid)
          expect(type.to_global_id.to_s).to eq collection_type_gid
        end
      end

      context "and collection type has permissions" do
        let(:manager) { FactoryBot.create(:user, email: 'manager@example.com') }
        let(:collection_type) { FactoryBot.create(:collection_type, manager_user: manager.user_key) }

        it "copies collection type permissions to collection" do
          parameters = { collection: collection_attrs,
                         collection_type_gid: collection_type.to_global_id.to_s }

          # adds admin group, depositing user, and manager from collection type
          expect { post :create, params: parameters }
            .to change { Hyrax::PermissionTemplate.count }
            .by(1)
            .and change { Hyrax::PermissionTemplateAccess.count }
            .by(3)

          expect(assigns[:collection].edit_users).to contain_exactly manager.user_key, user.user_key
          expect(assigns[:collection].edit_groups).to contain_exactly 'admin'
        end
      end
    end

    context "when params includes parent_id" do
      let(:parent_collection) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Parent']) }

      it "creates a collection as a subcollection of parent" do
        parameters = { collection: collection_attrs, parent_id: parent_collection.id }

        expect { post :create, params: parameters }
          .to change { Hyrax.query_service.count_all_of_model(model: Hyrax::PcdmCollection) }
          .by(1)

        collection = Hyrax.query_service.find_by(id: assigns[:collection].id)
        expect(queries.find_collections_for(resource: collection).map(&:id))
          .to contain_exactly(parent_collection.id)
      end
    end

    context "when create fails" do
      before do
        allow(controller).to receive(:authorize!)
        allow(Hyrax::PcdmCollection).to receive(:new).and_return(collection)
        allow(Hyrax.persister)
          .to receive(:save)
          .with(resource: collection)
          .and_raise(StandardError, 'Failed to save collection')
      end

      let(:collection) { Hyrax::PcdmCollection.new }

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
        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                  new_members: [asset1, asset2],
                                                                  user: user)
        else
          [asset1, asset2].each do |asset|
            asset.member_of_collections << collection
            asset.save!
          end
        end
      end

      it "adds members to the collection from edit form" do
        parameters = { id: collection,
                       collection: { members: 'add' },
                       batch_document_ids: [asset3.id],
                       stay_on_edit: true }

        expect { put :update, params: parameters }
          .to change { queries.find_members_of(collection: collection).map(&:id) }
          .to contain_exactly(asset1.id, asset2.id, asset3.id)

        expect(response).to redirect_to routes.url_helpers.edit_dashboard_collection_path(collection, locale: 'en')
      end

      it "adds members to the collection from other than the edit form" do
        parameters = { id: collection,
                       collection: { members: 'add' },
                       batch_document_ids: [asset3.id] }
        expect { put :update, params: parameters }
          .to change { queries.find_members_of(collection: collection).map(&:id) }
          .to contain_exactly(asset1.id, asset2.id, asset3.id)

        expect(response).to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
      end

      it "removes members from the collection" do
        parameters = { id: collection,
                       collection: { members: 'remove' },
                       batch_document_ids: [asset2] }

        expect { put :update, params: parameters }
          .to change { queries.find_members_of(collection: collection).map(&:id) }
          .to contain_exactly(asset1.id)
      end

      it "publishes object.metadata.updated for removed objects" do
        parameters = { id: collection,
                       collection: { members: 'remove' },
                       batch_document_ids: [asset2] }

        expect { put :update, params: parameters }
          .to change { listener.object_metadata_updated&.payload }
          .to match(object: have_attributes(id: asset2.id), user: user)
      end
    end

    context 'when moving members between collections' do
      let(:asset1) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }
      let(:asset2) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }
      let(:asset3) { FactoryBot.valkyrie_create(:monograph, edit_users: [user]) }

      let(:collection2) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   title: ['Some Collection'],
                                   edit_users: [user])
      end

      before do
        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService
            .add_members(collection_id: collection.id,
                         new_members: [asset1, asset2, asset3],
                         user: user)
        else
          [asset1, asset2, asset3].each do |asset|
            asset.member_of_collections << collection
            asset.save
          end
        end
      end

      it 'moves the members' do # rubocop:disable RSpec/ExampleLength
        parameters = { id: collection,
                       collection: { members: 'move' },
                       destination_collection_id: collection2,
                       batch_document_ids: [asset2, asset3] }

        expect { put :update, params: parameters }
          .to change { queries.find_members_of(collection: collection).map(&:id) }
          .from(contain_exactly(asset1.id, asset2.id, asset3.id))
          .to(contain_exactly(asset1.id))
          .and change { queries.find_members_of(collection: collection2).map(&:id) }
          .from(be_none)
          .to(contain_exactly(asset2.id, asset3.id))
      end
    end

    context "updating a collections metadata" do
      it "saves the metadata" do
        expect { put :update, params: { id: collection, collection: { title: ['New Collection Title'] } } }
          .to change { Hyrax.query_service.find_by(id: collection.id).title }
          .to contain_exactly('New Collection Title')

        expect(flash[:notice]).to eq "Collection was successfully updated."
      end

      it "removes blank strings from params before updating Collection metadata" do # rubocop:disable RSpec/ExampleLength
        pending 'creation of a collection resource that includes basic metadata'
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

    context "updating a collection's visibility" do
      it "saves the visibility" do
        expect { put :update, params: { id: collection, collection: { title: ['Moomin in Space'], visibility: 'restricted' } } }
          .to change { Hyrax.query_service.find_by(id: collection.id).visibility }
          .from('open')
          .to('restricted')

        expect(flash[:notice]).to eq "Collection was successfully updated."
      end
    end

    context "when update fails" do
      before do
        collection # ensure the collection is loaded before we stub the persister save
        allow(Hyrax.persister)
          .to receive(:save)
          .with(any_args)
          .and_raise(StandardError, 'Failed to save collection')
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
        put :update, params: { id: collection,
                               banner_files: [uploaded.id],
                               collection: { creator: ['Emily'] },
                               update_collection: true }

        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id.to_s, role: "banner")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .to exist
      end

      it "don't save banner metadata when `update_collection` param is missing" do
        put :update, params: { id: collection,
                               banner_files: [uploaded.id],
                               collection: { creator: ['Emily'] } }

        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id.to_s, role: "banner")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .not_to exist
      end

      it "saves logo metadata" do # rubocop:disable RSpec/ExampleLength
        put :update, params: { id: collection,
                               logo_files: [uploaded.id],
                               alttext: ["Logo alt Text"],
                               linkurl: ["http://abc.com"],
                               collection: { creator: ['Emily'] },
                               update_collection: true }

        expect(CollectionBrandingInfo
                 .where(collection_id: collection.id.to_s,
                        role: "logo",
                        alt_text: "Logo alt Text",
                        target_url: "http://abc.com")
                 .where("local_path LIKE '%#{uploaded.file.filename}'"))
          .to exist
      end

      context 'where the linkurl is not a valid http|http link' do
        let(:uploaded) { FactoryBot.create(:uploaded_file) }

        it "does not save linkurl containing html; target_url is empty" do # rubocop:disable RSpec/ExampleLength
          put :update, params: { id: collection,
                                 logo_files: [uploaded.id],
                                 alttext: ["Logo alt Text"], linkurl: ["<script>remove_me</script>"],
                                 collection: { creator: ['Emily'] },
                                 update_collection: true }

          expect(
            CollectionBrandingInfo.where(
              collection_id: collection.id.to_s,
              target_url: "<script>remove_me</script>"
            ).where("target_url LIKE '%remove_me%)'")
          ).not_to exist
        end

        it "does not save linkurl containing dodgy protocol; target_url is empty" do # rubocop:disable RSpec/ExampleLength
          put :update, params: { id: collection,
                                 logo_files: [uploaded.id],
                                 alttext: ["Logo alt Text"],
                                 linkurl: ['javascript:alert("remove_me")'],
                                 collection: { creator: ['Emily'] },
                                 update_collection: true }

          expect(
            CollectionBrandingInfo.where(
              collection_id: collection.id.to_s,
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

        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService
            .add_members(collection_id: collection.id,
                         new_members: [asset1, asset2, asset3, asset4, asset5],
                         user: user)
        else
          [asset1, asset2, asset3, asset4, asset5].each do |asset|
            asset.member_of_collections << collection
            asset.save!
          end
        end
      end

      it "returns the collection and its members" do # rubocop:disable RSpec/ExampleLength
        expect(controller)
          .to receive(:add_breadcrumb)
          .with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with('Collections', Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with('My collection', collection_path(collection.id, locale: 'en'), "aria-current" => "page")

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
        FactoryBot.create(:private_collection,
                          title: ["My collection"],
                          description: ["My incredibly detailed description of the collection"],
                          user: user)
      end

      before do
        sign_in FactoryBot.create(:admin)

        allow(controller.current_ability)
          .to receive(:can?)
          .with(:show, anything)
          .and_return(true)
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
        expect(response.location).to eq Hyrax::Engine.routes.url_helpers.my_collections_path(locale: 'en')
      end
    end

    context "when an error occurs" do
      before do
        allow(Hyrax.persister)
          .to receive(:delete)
          .with(any_args)
          .and_raise(StandardError, "Failed to delete collection.")
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
      before { request.env['HTTP_REFERER'] = 'http://test.host/foo' }

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
      pending 'update of test to work with Hyrax::PcdmCollection'
      get :files, params: { id: collection }, format: :json

      expect(response).to be_successful
    end
  end
end
