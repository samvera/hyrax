# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability, :clean_repo do
  subject(:ability) { Ability.new(current_user) }
  let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com') }
  let(:user) { FactoryBot.create(:user, email: 'user@example.com') }
  let(:current_user) { user }

  context 'when admin user' do
    let(:current_user) { admin }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let(:admin_set) { FactoryBot.create(:adminset_lw, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, AdminSet) }
        it { is_expected.to be_able_to(:manage_any, AdminSet) }
        it { is_expected.to be_able_to(:create_any, AdminSet) }
        it { is_expected.to be_able_to(:create, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:create_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  context 'when admin set manager' do
    let(:current_user) { manager }
    let(:manager) { FactoryBot.create(:user, email: 'manager@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { FactoryBot.create(:adminset_lw, id: 'as_mu', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        FactoryBot.create(:permission_template_access,
                          :manage,
                          permission_template: admin_set.permission_template,
                          agent_type: 'user',
                          agent_id: manager.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: manager.user_key,
            access: Hyrax::PermissionTemplateAccess::MANAGE
          }
        ]
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:edit, admin_set) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, admin_set) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, admin_set) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
      end
    end
  end

  context 'when admin set depositor' do
    let(:current_user) { depositor }
    let(:depositor) { create(:user, email: 'depositor@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { create(:adminset_lw, id: 'as_du', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: admin_set.permission_template,
               agent_type: 'user',
               agent_id: depositor.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: depositor.user_key,
            access: Hyrax::PermissionTemplateAccess::DEPOSIT
          }
        ]
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:deposit, admin_set) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  context 'when admin set viewer' do
    let(:current_user) { viewer }
    let(:viewer) { create(:user, email: 'viewer@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let!(:admin_set) { create(:adminset_lw, id: 'as_vu', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      before do
        create(:permission_template_access,
               :view,
               permission_template: admin_set.permission_template,
               agent_type: 'user',
               agent_id: viewer.user_key)
        admin_set.permission_template.reset_access_controls_for(collection: admin_set)
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, access_grants: grants, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: viewer.user_key,
            access: Hyrax::PermissionTemplateAccess::VIEW
          }
        ]
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.to be_able_to(:view_admin_show, admin_set) }

        # There isn't a public show page for admin_sets, but since the user has
        # permission to view the admin show page, they have permission to view
        # the non-existent public show page.
        it { is_expected.to be_able_to(:read, admin_set) } # no public page for admin sets
        it { is_expected.to be_able_to(:read, solr_document) }
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end
  end

  context 'when user has no special access' do
    let(:current_user) { other_user }
    let(:other_user) { FactoryBot.create(:user, email: 'other_user@example.com') }

    context 'and admin set is an ActiveFedora::Base', :active_fedora do
      let(:admin_set) { FactoryBot.create(:adminset_lw, id: 'as', user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, AdminSet) }
        it { is_expected.not_to be_able_to(:manage_any, AdminSet) }
        it { is_expected.not_to be_able_to(:create_any, AdminSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, AdminSet) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, AdminSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, admin_set) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and admin set is a valkyrie resource' do
      let!(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, user: user, with_permission_template: true) }
      let!(:solr_document) { SolrDocument.new(Hyrax::AdministrativeSetIndexer.new(resource: admin_set).to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:create_any, Hyrax::AdministrativeSet) } # granted by collection type, not collection
        it { is_expected.not_to be_able_to(:create, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, Hyrax::AdministrativeSet) }
        it { is_expected.not_to be_able_to(:edit, admin_set) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, admin_set) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, admin_set) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, admin_set) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, admin_set) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, admin_set) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end
end
