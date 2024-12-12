# frozen_string_literal: true
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Dashboard::CollectionsController, :clean_repo do
  ['Collection', 'CollectionResource'].each do |model|
    context "with model #{model}" do
      before { allow(Hyrax.config).to receive(:collection_model).and_return(model) }

      routes { Hyrax::Engine.routes }
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
                                   creator: user.user_key,
                                   depositor: user.user_key,
                                   edit_users: [user])
      end

      let(:collection_attrs) do
        { title: ['My First Collection'],
          creator: ["Mrs. Smith"],
          description: ["The Description\r\n\r\nand more"],
          collection_type_gid: [collection_type_gid.to_s] }
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

        # rubocop:disable RSpec/ExampleLength
        it "creates a Collection with old style parameters" do
          skip("these parameters are deprecated for AF models, and not supported for Valkyrie") if
            Hyrax.config.collection_class < Valkyrie::Resource

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

          expect(assigns[:collection].visibility).to eq 'open'
          expect(assigns[:collection].edit_users).to contain_exactly "archivist1", user.email
          expect(flash[:notice]).to eq "Collection was successfully created."
        end

        it "removes blank strings from params before creating Collection" do
          post :create, params: { collection: collection_attrs.merge(creator: ['']) }

          expect(assigns[:collection].title).to contain_exactly("My First Collection")
          expect(assigns[:collection].creator).to be_blank
        end

        it "sets current user as the depositor" do
          post :create, params: { collection: collection_attrs }

          expect(assigns[:collection].depositor).to eq user.user_key
        end

        context "with files I can access" do
          it "creates a collection using only the accessible files" do
            parameters = { collection: collection_attrs,
                           batch_document_ids: [asset1.id, asset2.id, unowned_asset.id] }

            post :create, params: parameters

            collection = assigns(:collection).try(:valkyrie_resource) ||
                         assigns(:collection)

            expect(queries.find_members_of(collection: collection).map(&:id))
              .to contain_exactly(asset1.id, asset2.id)
          end

          it "adds docs to the collection and adds the collection id to the documents in the collection" do
            post :create, params: { batch_document_ids: [asset1.id, unowned_asset.id],
                                    collection: collection_attrs }

            collection = assigns(:collection).try(:valkyrie_resource) ||
                         assigns(:collection)

            expect(queries.find_members_of(collection: collection).map(&:id))
              .to contain_exactly(asset1.id)
            asset_results = Hyrax::SolrService.get(fq: ["id:\"#{asset1.id}\""], fl: ['id', "collection_tesim"])
            expect(asset_results["response"]["numFound"]).to eq 1
            doc = asset_results["response"]["docs"].first
            expect(doc["id"]).to eq asset1.id
          end
        end

        context 'when setting collection type' do
          let(:collection_type) { FactoryBot.create(:collection_type) }

          it "creates a Collection of default type when type is nil" do
            post :create, params: { collection: collection_attrs }

            type = GlobalID::Locator.locate(assigns[:collection].collection_type_gid)

            expect(type.machine_id)
              .to eq Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
          end

          it "creates a Collection of specified type" do
            post :create, params: { collection: collection_attrs,
                                    collection_type_gid: collection_type.to_global_id.to_s }

            expect(assigns[:collection].collection_type_gid)
              .to eq collection_type.to_global_id.to_s
          end

          context 'and collection type is not passed in' do
            let(:user_collection_type) { FactoryBot.create(:user_collection_type) }
            let!(:user_collection_type_gid) { user_collection_type.to_global_id.to_s }
            let(:collection_type_gid) { user_collection_type_gid }

            it 'assigns the default User Collection' do
              post :create, params: { collection: collection_attrs }

              type = GlobalID::Locator.locate(assigns[:collection].collection_type_gid)
              expect(type.to_global_id.to_s).to eq user_collection_type_gid
            end
          end

          context 'and collection type is not passed in' do
            let(:user_collection_type) { FactoryBot.create(:user_collection_type) }
            let!(:user_collection_type_gid) { user_collection_type.to_global_id.to_s }
            let(:collection_type_gid) { user_collection_type_gid }

            it 'assigns the default User Collection' do
              post :create, params: { collection: collection_attrs }

              type = GlobalID::Locator.locate(assigns[:collection].collection_type_gid)
              expect(type.to_global_id.to_s).to eq user_collection_type_gid
            end
          end

          context "and collection type has permissions" do
            describe ".create_default" do
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
        end

        context "when params includes parent_id" do
          let(:parent_collection) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Parent']) }

          it "creates a collection as a subcollection of parent" do
            parameters = { collection: collection_attrs, parent_id: parent_collection.id }

            post :create, params: parameters

            collection = assigns[:collection].try(:reload)&.valkyrie_resource ||
                         assigns[:collection]
            expect(queries.find_collections_for(resource: collection).map(&:id))
              .to contain_exactly(parent_collection.id)
          end
        end

        context "when create fails" do
          let(:collection) { Hyrax.config.collection_class.new }
          let(:error) { "Failed to save collection" }
          let(:step) { double('change_set.apply', call: Dry::Monads::Failure([error])) }

          before do
            allow(controller).to receive(:authorize!)
            allow(Hyrax.config.collection_class).to receive(:new).and_return(collection)

            if Hyrax.config.collection_class < ActiveFedora::Base
              allow(collection).to receive(:save).and_return(false)
              allow(collection).to receive(:errors).and_return(error)
            else
              allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
              allow(Hyrax::Transactions::Container).to receive(:[]).with('change_set.apply').and_return(step)
            end
          end

          it "renders the form again" do
            post :create, params: { collection: collection_attrs }

            expect(response).to render_template(:new)
            expect(flash[:error]).to include error
          end

          it "renders json" do
            post :create, params: { collection: collection_attrs, format: :json }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.media_type).to eq "application/json"
            expect(response.body).to include error
          end

          context "in validations" do
            let(:form) { instance_double(Hyrax::Forms::PcdmCollectionForm, errors: errors) }
            let(:errors) { instance_double(Reform::Contract::CustomError, messages: messages) }
            let(:messages) { { publisher: ["must exist"] } }
            let(:errmsg) { "publisher must exist" }

            before do
              skip("these validations only apply to Valkyrie forms") if
                Hyrax.config.collection_class < ActiveFedora::Base
              allow(controller).to receive(:authorize!)
              allow(Hyrax::Forms::ResourceForm).to receive(:for).and_return(form)
              allow(form).to receive(:validate).with(any_args).and_return(false)
              allow(form).to receive(:prepopulate!).with(any_args).and_return(true)
            end

            let(:collection) { Hyrax.config.collection_class.new }

            it "renders the form again" do
              post :create, params: { collection: collection_attrs }

              expect(response).to have_http_status(:unprocessable_entity)
              expect(flash[:error]).to eq errmsg
              expect(response).to render_template(:new)
            end

            it "renders json" do
              post :create, params: { collection: collection_attrs, format: :json }

              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.media_type).to eq "application/json"

              json_response = JSON.parse(response.body)
              expect(json_response["code"]).to eq 422
              expect(json_response["message"]).to eq "Unprocessable Entity"
              expect(json_response["description"]).to eq "The resource you attempted to modify cannot be modified according to your request."
              expect(json_response["errors"]).to eq errmsg
            end
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

          it 'moves the members' do
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

          it "removes blank strings from params before updating Collection metadata" do
            put :update, params: {
              id: collection,
              collection: {
                title: ["My Next Collection-"],
                creator: [""]
              }
            }

            expect(assigns[:collection].title).to contain_exactly("My Next Collection-")
            expect(assigns[:collection].creator).to be_blank
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
          let!(:collection) { FactoryBot.valkyrie_create(:collection_resource) }
          let(:repository) { instance_double(Blacklight::Solr::Repository, search: result) }
          let(:result) { double(documents: [], total: 0) }
          let(:error) { "Failed to save collection" }
          let(:step) { double('change_set.apply', call: Dry::Monads::Failure([error])) }

          before do
            allow(controller).to receive(:authorize!)

            if Hyrax.config.collection_class < ActiveFedora::Base
              existing = ActiveFedora::Base.find(collection.id.to_s)

              allow(Collection).to receive(:find).and_return(existing)
              allow(existing).to receive(:update).and_return(false)
              allow(existing).to receive(:errors).and_return(error)
              allow(controller).to receive(:repository).and_return(repository)
              allow_any_instance_of(::Collection).to receive(:save).and_return(false)
            else
              allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
              allow(Hyrax::Transactions::Container).to receive(:[]).with('change_set.apply').and_return(step)
            end
          end

          it "renders the form again" do
            put :update, params: { id: collection, collection: collection_attrs }

            expect(flash[:error]).to match(/#{error}/)
            expect(response).to render_template(:edit)
          end

          it "renders json" do
            put :update, params: {
              id: collection,
              collection: collection_attrs,
              format: :json
            }

            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.media_type).to eq "application/json"
            expect(response.body).to match(/Failed to save collection/)
          end

          context "in validations" do
            let(:form) { instance_double(Hyrax::Forms::PcdmCollectionForm, errors: errors) }
            let(:errors) { instance_double(Reform::Contract::CustomError, messages: messages) }
            let(:messages) { { publisher: ["must exist"] } }
            let(:errmsg) { "publisher must exist" }

            before do
              skip("these validations only apply to Valkyrie forms") if
                Hyrax.config.collection_class < ActiveFedora::Base

              allow(Hyrax::Forms::ResourceForm).to receive(:for).and_return(form)
              allow(form).to receive(:validate).with(any_args).and_return(false)
              allow(form).to receive(:prepopulate!).with(any_args).and_return(true)
            end

            it "renders the form again" do
              put :update, params: { id: collection, collection: collection_attrs }

              expect(response).to have_http_status(:unprocessable_entity)
              expect(flash[:error]).to eq errmsg
              expect(response).to render_template(:edit)
            end

            it "renders json" do
              put :update, params: {
                id: collection,
                collection: collection_attrs,
                format: :json
              }
              expect(response).to have_http_status(:unprocessable_entity)
              expect(response.media_type).to eq "application/json"

              json_response = JSON.parse(response.body)
              expect(json_response["code"]).to eq 422
              expect(json_response["message"]).to eq "Unprocessable Entity"
              expect(json_response["description"]).to eq "The resource you attempted to modify cannot be modified according to your request."
              expect(json_response["errors"]).to eq errmsg
            end
          end
        end

        context "updating a collections branding metadata" do
          let(:uploaded) { FactoryBot.create(:uploaded_file) }

          it "saves banner metadata" do
            put :update, params: { id: collection,
                                   banner_files: [uploaded.id],
                                   collection: { creator: ['Emily'] } }

            expect(CollectionBrandingInfo
                     .where(collection_id: collection.id.to_s, role: "banner")
                     .where("local_path LIKE '%#{uploaded.file.filename}'"))
              .to exist
          end

          it "saves logo metadata" do
            put :update, params: { id: collection,
                                   logo_files: [uploaded.id],
                                   alttext: ["Logo alt Text"],
                                   linkurl: ["http://abc.com"],
                                   collection: { creator: ['Emily'] } }

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

            it "does not save linkurl containing html; target_url is empty" do
              put :update, params: { id: collection,
                                     logo_files: [uploaded.id],
                                     alttext: ["Logo alt Text"], linkurl: ["<script>remove_me</script>"],
                                     collection: { creator: ['Emily'] } }

              expect(
                CollectionBrandingInfo.where(
                  collection_id: collection.id.to_s,
                  target_url: "<script>remove_me</script>"
                ).where("target_url LIKE '%remove_me%)'")
              ).not_to exist
            end

            it "does not save linkurl containing dodgy protocol; target_url is empty" do
              put :update, params: { id: collection,
                                     logo_files: [uploaded.id],
                                     alttext: ["Logo alt Text"],
                                     linkurl: ['javascript:alert("remove_me")'],
                                     collection: { creator: ['Emily'] } }

              expect(
                CollectionBrandingInfo.where(
                  collection_id: collection.id.to_s,
                  target_url: 'javascript:alert("remove_me")'
                ).where("target_url LIKE '%remove_me%)'")
              ).not_to exist
            end
          end
        end

        context 'with nested collection' do
          let(:parent_collection) { FactoryBot.valkyrie_create(:collection_resource) }
          let(:collection) do
            FactoryBot.valkyrie_create(:collection_resource,
              :public,
              title: ["My collection"],
              creator: ["Mr. Smith"],
              depositor: user.user_key,
              edit_users: [user],
              member_of_collection_ids: [parent_collection.id])
          end

          it 'retains parent collection relationship' do
            skip "this was never tested in ActiveFedora" if
              Hyrax.config.collection_class < ActiveFedora::Base

            put :update, params: { id: collection, collection: { description: ['Videos of importance'] } }
            expect(assigns[:collection].description).to eq ['Videos of importance']
            expect(assigns[:collection].member_of_collection_ids).to eq [parent_collection.id]
          end
        end
      end

      describe "#show" do
        before do
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

        context "when not signed in" do
          it "is not successful" do
            get :show, params: { id: collection }

            expect(response).not_to be_successful
          end
        end

        context "when signed in" do
          before do
            sign_in user
          end

          it "returns the collection and its members" do
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
              .with('My collection', collection_path(collection.id, locale: 'en'), { "aria-current" => "page" })

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
              expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), { "aria-current" => "page" })
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
              expect(controller).to receive(:add_breadcrumb).with('My collection', collection_path(collection.id, locale: 'en'), { "aria-current" => "page" })
              get :show, params: { id: collection }
              expect(response).to be_successful
            end
          end
        end

        context 'with admin user and private collection' do
          let(:collection) do
            FactoryBot.valkyrie_create(:hyrax_collection,
                              title: ["My collection"],
                              description: ["My incredibly detailed description of the collection"],
                              edit_users: [user])
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
          end
        end

        context "when an error occurs" do
          let(:error) { "Collection could not be deleted" }
          let(:step) { double('collection_resource.delete', call: Dry::Monads::Failure([error])) }

          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(Collection).to receive(:destroy).and_return(nil)
            # rubocop:enable RSpec/AnyInstance

            allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
            allow(Hyrax::Transactions::Container).to receive(:[]).with('collection_resource.delete').and_return(step)
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
            expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.collection.edit_view"), collection_path(collection.id, locale: 'en'), { "aria-current" => "page" })
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
            expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.collection.edit_view"), collection_path(collection.id, locale: 'en'), { "aria-current" => "page" })

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

      describe "#index" do
        context "when not signed in" do
          it "is not successful" do
            get :index, params: { id: collection }

            expect(response).not_to be_successful
          end
        end

        context "when signed in" do
          before do
            sign_in user
          end

          it "sets breadcrumbs" do
            expect(controller).to receive(:add_breadcrumb).with('Home', root_path(locale: 'en'))
            expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path(locale: 'en'))
            expect(controller).to receive(:add_breadcrumb).with('Collections', my_collections_path(locale: 'en'))
            get :index, params: { per_page: 1 }
          end
        end
      end
    end
  end
end
