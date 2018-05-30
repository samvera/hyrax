RSpec.describe 'Collections Factory' do # rubocop:disable RSpec/DescribeClass
  let(:user) { build(:user, email: 'user@example.com') }
  let(:user_mgr) { build(:user, email: 'user_mgr@example.com') }
  let(:user_dep) { build(:user, email: 'user_dep@example.com') }
  let(:user_vw) { build(:user, email: 'user_vw@example.com') }
  let(:collection_type) { create(:collection_type) }

  describe 'build' do
    context 'with collection_type_settings and/or collection_type_gid' do
      it 'will use the default User Collection type when neither is specified' do
        col = build(:collection_lw)
        expect(col.collection_type.title).to eq 'User Collection'
        expect(col.collection_type.machine_id).to eq 'user_collection'
      end

      it 'uses collection type for passed in collection_type_gid when collection_type_settings is nil' do
        col = build(:collection_lw, collection_type_gid: collection_type.gid)
        expect(col.collection_type_gid).to eq collection_type.gid
      end

      it 'ignores collection_type_gid when collection_type_settings is set to attributes identifying settings' do
        col = build(:collection_lw, collection_type_settings: [:not_discoverable, :not_sharable], collection_type_gid: collection_type.gid)
        expect(col.collection_type_gid).not_to eq collection_type.gid
      end

      it 'will create a collection type when collection_type_settings is set to attributes identifying settings' do
        expect { build(:collection_lw, collection_type_settings: [:discoverable]) }.to change { Hyrax::CollectionType.count }.by(1)
        expect { build(:collection_lw, collection_type_settings: [:not_discoverable, :not_sharable]) }.to change { Hyrax::CollectionType.count }.by(1)
      end

      it 'will create a collection type with specified settings when collection_type_settings is set to attributes identifying settings' do
        col = build(:collection_lw, collection_type_settings: [:not_discoverable, :not_sharable, :not_brandable, :nestable])
        expect(col.collection_type.discoverable?).to be false
        expect(col.collection_type.sharable?).to be false
        expect(col.collection_type.brandable?).to be false
        expect(col.collection_type.nestable?).to be true
      end
    end

    context 'with_permission_template' do
      it 'will not create a permission template or access when it is the default value of false' do
        expect { build(:collection_lw) }.not_to change { Hyrax::PermissionTemplate.count }
        expect { build(:collection_lw) }.not_to change { Hyrax::PermissionTemplateAccess.count }
      end

      it 'will create a permission template and one access for the creating user when set to true' do
        expect { build(:collection_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:collection_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplateAccess.count }.by(1)
      end

      it 'will create a permission template and access for each user specified when it is set to attributes identifying access' do
        expect { build(:collection_lw, with_permission_template: { manage_users: [user_mgr] }) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:collection_lw, with_permission_template: { manage_users: [user_mgr] }) }.to change { Hyrax::PermissionTemplateAccess.count }.by(2)
        expect { build(:collection_lw, with_permission_template: { manage_users: [user_mgr], deposit_users: [user_dep], view_users: [user_vw] }) }
          .to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:collection_lw, with_permission_template: { manage_users: [user_mgr], deposit_users: [user_dep], view_users: [user_vw] }) }
          .to change { Hyrax::PermissionTemplateAccess.count }.by(4)
      end
    end

    context 'with_solr_document' do
      it 'will not create a solr document by default' do
        col = build(:collection_lw)
        expect(col.id).to eq nil # no real way to confirm a solr document wasn't created if the collection doesn't have an id
      end

      context 'true' do
        let(:col) { build(:collection_lw, with_solr_document: true) }

        subject { ActiveFedora::SolrService.get("id:#{col.id}")["response"]["docs"].first }

        it 'will create a solr document' do
          expect(subject["id"]).to eq col.id
          expect(subject["has_model_ssim"].first).to eq "Collection"
          expect(subject["edit_access_person_ssim"]).not_to be_blank
        end
      end

      context 'true and with_permission_template defines additional access' do
        let(:col) do
          build(:collection_lw, user: user,
                                with_solr_document: true,
                                with_permission_template: { manage_users: [user_mgr],
                                                            deposit_users: [user_dep],
                                                            view_users: [user_vw] })
        end

        subject { ActiveFedora::SolrService.get("id:#{col.id}")["response"]["docs"].first }

        it 'will create a solr document' do
          expect(subject["id"]).to eq col.id
          expect(subject["has_model_ssim"].first).to eq "Collection"
          expect(subject["edit_access_person_ssim"]).to include(user.user_key, user_mgr.user_key)
          expect(subject["read_access_person_ssim"]).to include(user_dep.user_key, user_vw.user_key)
        end
      end
    end

    context 'with_nesting_attributes' do
      let(:collection_type) { create(:collection_type) }
      let(:blacklight_config) { CatalogController.blacklight_config }
      let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }
      let(:current_ability) { instance_double(Ability, admin?: true) }
      let(:scope) { double('Scope', can?: true, current_ability: current_ability, repository: repository, blacklight_config: blacklight_config) }
      let(:solr_doc) { ActiveFedora::SolrService.get("id:#{col.id}")["response"]["docs"].first }
      let(:nesting_attributes) do
        Hyrax::Collections::NestedCollectionQueryService::NestingAttributes.new(id: col.id, scope: scope)
      end

      context 'without additional permissions' do
        let(:col) do
          build(:collection_lw, id: 'Collection123',
                                collection_type_gid: collection_type.gid,
                                with_nesting_attributes: { ancestors: ['Parent_1'],
                                                           parent_ids: ['Parent_1'],
                                                           pathnames: ['Parent_1/Collection123'],
                                                           depth: 2 })
        end

        it 'will persist a queryable solr document with the given attributes' do
          expect(nesting_attributes.id).to eq('Collection123')
          expect(nesting_attributes.parents).to eq(['Parent_1'])
          expect(nesting_attributes.pathnames).to eq(['Parent_1/Collection123'])
          expect(nesting_attributes.ancestors).to eq(['Parent_1'])
          expect(nesting_attributes.depth).to eq(2)
          expect(solr_doc["id"]).to eq col.id
          expect(solr_doc["has_model_ssim"].first).to eq "Collection"
          expect(solr_doc["edit_access_person_ssim"]).to include(col.depositor)
        end
      end

      context ' and with_permission_template' do
        let(:col) do
          build(:collection_lw, id: 'Collection123',
                                collection_type_gid: collection_type.gid,
                                with_nesting_attributes: { ancestors: ['Parent_1'],
                                                           parent_ids: ['Parent_1'],
                                                           pathnames: ['Parent_1/Collection123'],
                                                           depth: 2 },
                                with_permission_template: { manage_users: [user_mgr],
                                                            deposit_users: [user_dep],
                                                            view_users: [user_vw] })
        end

        it 'will persist a queryable solr document with the given attributes' do
          expect(nesting_attributes.id).to eq('Collection123')
          expect(nesting_attributes.parents).to eq(['Parent_1'])
          expect(nesting_attributes.pathnames).to eq(['Parent_1/Collection123'])
          expect(nesting_attributes.ancestors).to eq(['Parent_1'])
          expect(nesting_attributes.depth).to eq(2)
          expect(solr_doc["id"]).to eq col.id
          expect(solr_doc["has_model_ssim"].first).to eq "Collection"
          expect(solr_doc["edit_access_person_ssim"]).to include(col.depositor, user_mgr.user_key)
          expect(solr_doc["read_access_person_ssim"]).to include(user_dep.user_key, user_vw.user_key)
        end
      end

      context 'and with_permission_template and with_solr_document' do
        let(:col) do
          build(:collection_lw, id: 'Collection123',
                                collection_type_gid: collection_type.gid,
                                with_nesting_attributes: { ancestors: ['Parent_1'],
                                                           parent_ids: ['Parent_1'],
                                                           pathnames: ['Parent_1/Collection123'],
                                                           depth: 2 },
                                with_permission_template: { manage_users: [user_mgr],
                                                            deposit_users: [user_dep],
                                                            view_users: [user_vw] },
                                with_solr_document: true)
        end

        it 'will persist a queryable solr document with the given attributes' do
          expect(nesting_attributes.id).to eq('Collection123')
          expect(nesting_attributes.parents).to eq(['Parent_1'])
          expect(nesting_attributes.pathnames).to eq(['Parent_1/Collection123'])
          expect(nesting_attributes.ancestors).to eq(['Parent_1'])
          expect(nesting_attributes.depth).to eq(2)
          expect(solr_doc["id"]).to eq col.id
          expect(solr_doc["has_model_ssim"].first).to eq "Collection"
          expect(solr_doc["edit_access_person_ssim"]).to include(col.depositor, user_mgr.user_key)
          expect(solr_doc["read_access_person_ssim"]).to include(user_dep.user_key, user_vw.user_key)
        end
      end
    end
  end

  describe 'create' do
    # collection_type_settings and collection_type_gid are tested by `build` and are the same for `build` and `create`
    # with_solr_document is tested by build
    # with_permission_template is tested by build except that the permission template is always created for `create`
    # with_nested_attributes not supported for create

    context 'with_permission_template' do
      it 'will create a permission template and access even when it is the default value of false' do
        expect { create(:collection_lw) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { create(:collection_lw) }.to change { Hyrax::PermissionTemplateAccess.count }.by(1)
      end
    end

    context 'when including nesting indexing', with_nested_reindexing: true do
      # Nested indexing requires that the user's permissions be saved
      # on the Fedora object... if simply in local memory, they are
      # lost when the adapter pulls the object from Fedora to reindex.
      let(:user) { create(:user) }
      let(:collection) { create(:collection_lw, user: user) }

      it 'will authorize the creating user' do
        expect(user.can?(:edit, collection)).to be true
      end
    end
  end
end
