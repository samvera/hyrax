RSpec.describe 'AdminSets Factory' do # rubocop:disable RSpec/DescribeClass
  let(:user) { build(:user, email: 'user@example.com') }
  let(:user_mgr) { build(:user, email: 'user_mgr@example.com') }
  let(:user_dep) { build(:user, email: 'user_dep@example.com') }
  let(:user_vw) { build(:user, email: 'user_vw@example.com') }

  describe 'build' do
    context 'with_permission_template' do
      it 'will not create a permission template or access when it is the default value of false' do
        expect { build(:adminset_lw) }.not_to change { Hyrax::PermissionTemplate.count }
        expect { build(:adminset_lw) }.not_to change { Hyrax::PermissionTemplateAccess.count }
      end

      it 'will create a permission template and one access for the creating user when set to true' do
        expect { build(:adminset_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:adminset_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplateAccess.count }.by(1)
      end

      it 'will create a permission template and access for each user specified when it is set to attributes identifying access' do
        expect { build(:adminset_lw, with_permission_template: { manage_users: [user_mgr] }) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:adminset_lw, with_permission_template: { manage_users: [user_mgr] }) }.to change { Hyrax::PermissionTemplateAccess.count }.by(2)
        expect { build(:adminset_lw, with_permission_template: { manage_users: [user_mgr], deposit_users: [user_dep], view_users: [user_vw] }) }
          .to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:adminset_lw, with_permission_template: { manage_users: [user_mgr], deposit_users: [user_dep], view_users: [user_vw] }) }
          .to change { Hyrax::PermissionTemplateAccess.count }.by(4)
      end
    end

    context 'with_solr_document' do
      it 'will not create a solr document by default' do
        adminset = build(:adminset_lw)
        expect(adminset.id).to eq nil # no real way to confirm a solr document wasn't created if the admin set doesn't have an id
      end

      context 'true' do
        let(:adminset) { build(:adminset_lw, with_solr_document: true) }

        subject { ActiveFedora::SolrService.get("id:#{adminset.id}")["response"]["docs"].first }

        it 'will create a solr document' do
          expect(subject["id"]).to eq adminset.id
          expect(subject["has_model_ssim"].first).to eq "AdminSet"
          expect(subject["edit_access_person_ssim"]).not_to be_blank
        end
      end

      context 'true and with_permission_template defines additional access' do
        let(:adminset) do
          build(:adminset_lw, user: user,
                              with_solr_document: true,
                              with_permission_template: { manage_users: [user_mgr],
                                                          deposit_users: [user_dep],
                                                          view_users: [user_vw] })
        end

        subject { ActiveFedora::SolrService.get("id:#{adminset.id}")["response"]["docs"].first }

        it 'will created a solr document' do
          expect(subject["id"]).to eq adminset.id
          expect(subject["has_model_ssim"].first).to eq "AdminSet"
          expect(subject["edit_access_person_ssim"]).to include(user.user_key, user_mgr.user_key)
          expect(subject["read_access_person_ssim"]).to include(user_dep.user_key, user_vw.user_key)
        end
      end
    end
  end

  describe 'create' do
    # with_solr_document is tested by build
    # with_permission_template is tested by build except that the permission template is always created for `create`

    context 'with_permission_template: false' do
      it 'will create a permission template and access even when it is the default value of false' do
        expect { create(:adminset_lw) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { create(:adminset_lw) }.to change { Hyrax::PermissionTemplateAccess.count }.by(1)
      end
    end
  end

  describe 'default_adminset' do
    let(:default_adminset) { build(:default_adminset) }
    let(:solrdoc) { ActiveFedora::SolrService.get("id:#{default_adminset.id}")["response"]["docs"].first }
    let(:permission_template) { default_adminset.permission_template }

    it 'will create the default adminset with expected metadata' do
      expect(default_adminset.id).to eq AdminSet::DEFAULT_ID
      expect(default_adminset.title).to eq AdminSet::DEFAULT_TITLE
    end

    it 'will create solr doc with no access' do
      expect(solrdoc["id"]).to eq default_adminset.id
      expect(solrdoc["has_model_ssim"].first).to eq "AdminSet"
      expect(solrdoc["edit_access_person_ssim"].count).to eq 1 # creator automatically assigned by factory
      expect(solrdoc["read_access_person_ssim"]).to eq nil
      expect(solrdoc["edit_access_group_ssim"]).to include(::Ability.admin_group_name)
      expect(solrdoc["read_access_group_ssim"]).to eq nil
    end

    it 'will create permission template with registered users as depositors' do
      expect(permission_template.agent_ids_for(access: 'deposit', agent_type: 'group'))
        .to include(::Ability.registered_group_name)
      expect(permission_template.agent_ids_for(access: 'manage', agent_type: 'group'))
        .to include(::Ability.admin_group_name)
    end
  end

  describe 'build no_solr_grants_adminset' do
    let(:permissions) do
      { manage_users: [user_mgr],
        deposit_users: [user_dep],
        view_users: [user_vw] }
    end
    let(:legacy_adminset) { build(:no_solr_grants_adminset, user: user, with_permission_template: permissions) }
    let(:solrdoc) { ActiveFedora::SolrService.get("id:#{legacy_adminset.id}")["response"]["docs"].first }

    it 'will create a permission template with all access' do
      expect { build(:no_solr_grants_adminset, user: user, with_permission_template: permissions) }
        .to change { Hyrax::PermissionTemplate.count }.by(1)
      expect { build(:no_solr_grants_adminset, user: user, with_permission_template: permissions) }
        .to change { Hyrax::PermissionTemplateAccess.count }.by(4)
    end

    it 'will create solr doc with creator access only' do
      expect(solrdoc["id"]).to eq legacy_adminset.id
      expect(solrdoc["has_model_ssim"].first).to eq "AdminSet"
      expect(solrdoc["edit_access_person_ssim"]).to eq [user.user_key]
      expect(solrdoc["read_access_person_ssim"]).to eq nil
      expect(solrdoc["edit_access_group_ssim"]).to eq nil
      expect(solrdoc["read_access_group_ssim"]).to eq nil
    end
  end
end
