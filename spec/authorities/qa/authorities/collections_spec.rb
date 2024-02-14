# frozen_string_literal: true

# @todo FactoryBot.build seems to be used to force indexing.
#   this can probably be refactored to just index the content we want the
#   authority service to find and avoid DB round trips associated with
#   `with_permission_template`,etc...
RSpec.describe Qa::Authorities::Collections, :clean_repo do
  subject(:service) { described_class.new }
  let(:controller) { Qa::TermsController.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let!(:collection1) { valkyrie_create(:hyrax_collection, title: ['foo foo'], user: user1) }

  let!(:collection2) { valkyrie_create(:hyrax_collection, title: ['bar'], user: user1) }

  let!(:collection3) { valkyrie_create(:hyrax_collection, title: ['another foo'], user: user1) }

  let!(:collection4) { valkyrie_create(:hyrax_collection, title: ['foo foo foo'], user: user2) }

  let!(:collection5) do
    valkyrie_create(:hyrax_collection,
                    title: ['foo for you'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::MANAGE }])
  end

  let!(:collection6) do
    valkyrie_create(:hyrax_collection,
                    title: ['foo too'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
  end

  let!(:collection7) do
    valkyrie_create(:hyrax_collection,
                    title: ['foo bar baz'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::VIEW }])
  end

  let!(:collection8) do
    valkyrie_create(:hyrax_collection,
                    title: ['bar for you'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::MANAGE }])
  end

  let!(:collection9) do
    valkyrie_create(:hyrax_collection,
                    title: ['bar too'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::DEPOSIT }])
  end

  let!(:collection10) do
    valkyrie_create(:hyrax_collection,
                    title: ['bar bar baz'],
                    user: user2,
                    access_grants: [{ agent_type: Hyrax::PermissionTemplateAccess::USER,
                                      agent_id: user1.user_key,
                                      access: Hyrax::PermissionTemplateAccess::VIEW }])
  end

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
  end

  describe '#search' do
    context 'when access is read' do
      let(:params) { ActionController::Parameters.new(q: 'foo', access: 'read') }

      it 'lists collections the current user can read' do
        expect(service.search(nil, controller))
          .to contain_exactly(include(id: collection1.id),
                              include(id: collection3.id),
                              include(id: collection5.id),
                              include(id: collection6.id),
                              include(id: collection7.id))
      end
    end

    context 'when access is edit' do
      let(:params) { ActionController::Parameters.new(q: 'foo', access: 'edit') }

      it 'lists collections the current user can edit' do
        expect(service.search(nil, controller))
          .to contain_exactly(include(id: collection1.id),
                              include(id: collection3.id),
                              include(id: collection5.id))
      end
    end

    context 'when access is deposit' do
      let(:params) { ActionController::Parameters.new(q: 'foo', access: 'deposit') }

      it 'lists collections the current user can edit or deposit' do
        expect(service.search(nil, controller))
          .to contain_exactly(include(id: collection1.id),
                              include(id: collection3.id),
                              include(id: collection5.id),
                              include(id: collection6.id))
      end
    end
  end
end
