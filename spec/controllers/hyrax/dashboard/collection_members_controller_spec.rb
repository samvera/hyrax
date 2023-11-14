# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::CollectionMembersController, :clean_repo do
  routes     { Hyrax::Engine.routes }
  let(:user) { FactoryBot.create(:user) }

  before { sign_in(user) }

  describe '#update_members' do
    let(:owned_work_1) { FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user]) }
    let(:owned_work_2) { FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user]) }
    let(:owned_work_3) { FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user]) }
    let(:private_work) { FactoryBot.valkyrie_create(:hyrax_work) }

    let(:queries) { Hyrax.custom_queries }

    let(:editable_work) do
      FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user])
    end

    let(:readable_work) do
      FactoryBot.valkyrie_create(:hyrax_work, read_users: [user])
    end

    let(:owned_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                        user: user)
    end

    let(:managed_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                        access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                          agent_id: user.user_key,
                                          access: Hyrax::PermissionTemplateAccess::MANAGE }])
    end

    let(:depositable_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                        access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                          agent_id: user.user_key,
                                          access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
    end

    let(:viewable_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection, read_users: [user])
    end

    let(:private_collection) do
      FactoryBot.valkyrie_create(:hyrax_collection)
    end

    let(:parameters) do
      { id: collection,
        collection: { members: 'add' },
        batch_document_ids: members_to_add.map(&:id) }
    end

    context 'when user created the collection' do
      let(:collection) { owned_collection }

      before do
        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                  new_members: [owned_work_1, owned_work_2],
                                                                  user: user)
        else
          [owned_work_1, owned_work_2].each do |asset|
            asset.member_of_collections << collection
            asset.save!
          end
        end
      end

      context 'and user created the work' do
        let(:members_to_add) { [owned_work_3] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end

        it 'redirects to dashboard collection show' do
          post :update_members, params: parameters

          expect(response)
            .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        end
      end

      context 'and user has edit access to works' do
        let(:members_to_add) { [editable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, editable_work.id)
        end
      end

      context 'and user has read access to works' do
        let(:members_to_add) { [readable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, readable_work.id)
        end
      end

      context 'and user has no access to a some works' do
        let(:members_to_add) { [owned_work_3, private_work] }

        it 'adds only members with read access' do
          expect { post :update_members, params: parameters }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end
      end

      context 'and user has no access to selected works' do
        let(:members_to_add) { [private_work] }

        it 'does not change membership' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection).count }

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end

        it 'flashes an error' do
          post :update_members, params: parameters

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end
      end

      context 'and user adds a subcollection' do
        let(:members_to_add) { [owned_collection] }

        it 'adds collection user created' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_collection.id)
        end

        it 'redirects to the dashboard collection show' do
          post(:update_members, params: parameters)

          expect(response)
            .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        end
      end

      context 'and user adds a collection with manage access' do
        let(:members_to_add) { [managed_collection] }

        it 'adds collection to members' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, managed_collection.id)
        end
      end

      context 'and user adds a collection with deposit access' do
        let(:members_to_add) { [depositable_collection] }

        it 'adds collection to members' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, depositable_collection.id)
        end
      end

      context 'and user adds a collection with view access' do
        let(:members_to_add) { [viewable_collection] }

        it 'adds collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, viewable_collection.id)
        end
      end

      context 'and user adds collection for which they have no access' do
        let(:members_to_add) { [private_collection] }

        it 'does not change membership ' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection).count }
        end

        it 'displays error message ' do
          post(:update_members, params: parameters)

          expect(flash[:alert]).to eq 'You do not have sufficient privileges to any of the selected members'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
        end
      end
    end

    context 'when user is a depositor on collection' do
      let(:collection) { depositable_collection }

      before do
        if collection.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                  new_members: [owned_work_1, owned_work_2],
                                                                  user: user)
        else
          [owned_work_1, owned_work_2].each do |asset|
            asset.member_of_collections << collection
            asset.save!
          end
        end
      end

      context 'and user created the work' do
        let(:members_to_add) { [owned_work_3] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end

        it 'redirects to dashboard collection show' do
          post :update_members, params: parameters

          expect(response)
            .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        end
      end

      context 'and user has edit access to works' do
        let(:members_to_add) { [editable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, editable_work.id)
        end
      end

      context 'and user has read access to works' do
        let(:members_to_add) { [readable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, readable_work.id)
        end
      end

      context 'and user has no access to a some works' do
        let(:members_to_add) { [owned_work_3, private_work] }

        it 'adds only members with read access' do
          expect { post :update_members, params: parameters }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .from(contain_exactly(owned_work_1.id, owned_work_2.id))
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_work_3.id)
        end
      end

      context 'and user has no access to selected works' do
        let(:members_to_add) { [private_work] }

        it 'does not change membership' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection).count }

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end

        it 'flashes an error' do
          post :update_members, params: parameters

          expect(flash[:alert])
            .to eq 'You do not have sufficient privileges to any of the selected members'
        end
      end

      context 'and user adds a subcollection' do
        let(:members_to_add) { [owned_collection] }

        it 'adds collection user created' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, owned_collection.id)
        end

        it 'redirects to the dashboard collection show' do
          post(:update_members, params: parameters)

          expect(response)
            .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
        end
      end

      context 'and user adds a collection with manage access' do
        let(:members_to_add) { [managed_collection] }

        it 'adds collection to members' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, managed_collection.id)
        end
      end

      context 'and user adds a collection with deposit access' do
        let(:members_to_add) { [depositable_collection] }

        it 'adds collection to members' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, depositable_collection.id)
        end
      end

      context 'and user adds a collection with view access' do
        let(:members_to_add) { [viewable_collection] }

        it 'adds collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_work_1.id, owned_work_2.id, viewable_collection.id)
        end
      end

      context 'and user adds collection for which they have no access' do
        let(:members_to_add) { [private_collection] }

        it 'does not change membership ' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection).count }
        end

        it 'displays error message ' do
          post(:update_members, params: parameters)

          expect(flash[:alert]).to eq 'You do not have sufficient privileges to any of the selected members'
          expect(response).to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
        end
      end
    end

    context 'when user is manager of the collection' do
      let(:collection) { managed_collection }

      context 'and user created the work' do
        let(:members_to_add) { [owned_collection] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(owned_collection.id)
        end
      end

      context 'and user has edit access to works' do
        let(:members_to_add) { [editable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(editable_work.id)
        end
      end

      context 'and user has read access to works' do
        let(:members_to_add) { [readable_work] }

        it 'adds members to the collection' do
          expect { post(:update_members, params: parameters) }
            .to change { queries.find_members_of(collection: collection).map(&:id) }
            .to contain_exactly(readable_work.id)
        end
      end

      context 'and user has no access to a work' do
        let(:members_to_add) { [private_work] }

        it 'declines to add members' do
          expect { post(:update_members, params: parameters) }
            .not_to change { queries.find_members_of(collection: collection).to_a }
            .from be_none
        end
      end

      context 'and user adds a subcollection' do
        context 'created by the user' do
          let(:members_to_add) { [owned_collection] }

          it 'adds collection' do
            expect { post(:update_members, params: parameters) }
              .to change { queries.find_members_of(collection: collection).map(&:id) }
              .to contain_exactly(owned_collection.id)
          end
        end

        context 'with manage access' do
          let(:members_to_add) { [managed_collection] }

          it 'adds collection' do
            expect { post(:update_members, params: parameters) }
              .to change { queries.find_members_of(collection: collection).map(&:id) }
              .to contain_exactly(managed_collection.id)
          end
        end

        context 'with manage access' do
          let(:members_to_add) { [managed_collection] }

          it 'adds collection' do
            expect { post(:update_members, params: parameters) }
              .to change { queries.find_members_of(collection: collection).map(&:id) }
              .to contain_exactly(managed_collection.id)
          end
        end

        context 'with deposit access' do
          let(:members_to_add) { [depositable_collection] }

          it 'adds collection' do
            expect { post(:update_members, params: parameters) }
              .to change { queries.find_members_of(collection: collection).map(&:id) }
              .to contain_exactly(depositable_collection.id)
          end
        end

        context 'with view access' do
          let(:members_to_add) { [viewable_collection] }

          it 'adds collection' do
            expect { post(:update_members, params: parameters) }
              .to change { queries.find_members_of(collection: collection).map(&:id) }
              .to contain_exactly(viewable_collection.id)
          end
        end

        context 'with no access' do
          let(:members_to_add) { [private_collection] }

          it 'does not add members' do
            expect { post(:update_members, params: parameters) }
              .not_to change { queries.find_members_of(collection: collection).to_a }
              .from be_none
          end

          it 'displays error' do
            post(:update_members, params: parameters)

            expect(flash[:alert])
              .to eq 'You do not have sufficient privileges to any of the selected members'
            expect(response)
              .to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
          end
        end
      end
    end

    context 'when user only a viewer of the collection' do
      let(:collection) { viewable_collection }
      let(:members_to_add) { [owned_work_3] }

      it 'does not add the work' do
        expect { post(:update_members, params: parameters) }
          .not_to change { queries.find_members_of(collection: collection).to_a }
          .from be_none
      end

      it 'displays error' do
        post(:update_members, params: parameters)

        expect(flash[:alert])
          .to eq 'You do not have sufficient privileges to add members to the collection'
        expect(response)
          .to redirect_to routes.url_helpers.dashboard_collections_path(locale: 'en')
      end
    end

    context 'when members violate the multi-membership checker for single membership collections' do
      let(:members_to_add) { [owned_work_1, owned_work_2, owned_work_3] }

      let(:single_membership_type) do
        FactoryBot.create(:collection_type, :not_allow_multiple_membership)
      end

      let(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                          collection_type: single_membership_type,
                          user: user)
      end

      let(:other_collection_of_type) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                          collection_type: single_membership_type,
                          user: user)
      end

      before do
        if other_collection_of_type.is_a? Valkyrie::Resource
          Hyrax::Collections::CollectionMemberService.add_members(collection_id: other_collection_of_type.id,
                                                                  new_members: [owned_work_1, owned_work_2],
                                                                  user: user)
        else
          [owned_work_1, owned_work_2].each do |asset|
            asset.member_of_collections << other_collection_of_type
            asset.save!
          end
        end
      end

      it "deposits works not in violation" do
        expect { post(:update_members, params: parameters) }
          .to change { queries.find_members_of(collection: collection).map(&:id) }
          .to contain_exactly(owned_work_3.id)
      end

      it "displays an error message" do
        post :update_members, params: parameters

        expect(flash[:error])
          .to match %r{Error\:\sYou\shave\sspecified\smore\sthan\sone\sof\sthe\s
                       same\ssingle-membership\scollection\stype\s\(type:\s
                       #{single_membership_type.title.gsub(' ', '\s')},\s
                       collections:\s
                       (#{other_collection_of_type.title.first.gsub(' ', '\s')}\s
                       and\s#{collection.title.first.gsub(' ', '\s')}|
                       #{collection.title.first.gsub(' ', '\s')}\sand\s
                       #{other_collection_of_type.title.first.gsub(' ', '\s')})}x

        expect(response)
          .to redirect_to routes.url_helpers.dashboard_collection_path(collection, locale: 'en')
      end
    end
  end
end
