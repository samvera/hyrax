# frozen_string_literal: true

# @todo FactoryBot.build seems to be used to force indexing.
#   this can probably be refactored to just index the content we want the
#   authority service to find and avoid DB round trips associated with
#   `with_permission_template`,etc...
RSpec.describe Qa::Authorities::Collections, :clean_repo do
  subject(:service) { described_class.new }
  let(:controller) { Qa::TermsController.new }
  let(:user1) { FactoryBot.build(:user) }
  let(:user2) { FactoryBot.build(:user) }

  let!(:collection1) do
    FactoryBot.build(:private_collection_lw,
                     title: ['foo foo'],
                     user: user1,
                     with_permission_template: true,
                     with_solr_document: true)
  end

  let!(:collection2) do
    FactoryBot.build(:private_collection_lw,
                     title: ['bar'],
                     user: user1,
                     with_permission_template: true,
                     with_solr_document: true)
  end

  let!(:collection3) do
    FactoryBot.build(:private_collection_lw,
                     title: ['another foo'],
                     user: user1,
                     with_permission_template: true,
                     with_solr_document: true)
  end

  let!(:collection4) do
    FactoryBot.build(:private_collection_lw,
                     title: ['foo foo foo'],
                     user: user2,
                     with_permission_template: true,
                     with_solr_document: true)
  end

  let!(:collection5) do
    FactoryBot.build(:private_collection_lw,
                     title: ['foo for you'],
                     user: user2,
                     with_permission_template: { manage_users: [user1] },
                     with_solr_document: true)
  end

  let!(:collection6) do
    FactoryBot.build(:private_collection_lw,
                     title: ['foo too'],
                     user: user2,
                     with_permission_template: { deposit_users: [user1] },
                     with_solr_document: true)
  end

  let!(:collection7) do
    FactoryBot.build(:private_collection_lw,
                     title: ['foo bar baz'],
                     user: user2,
                     with_permission_template: { view_users: [user1] },
                     with_solr_document: true)
  end

  let!(:collection8) do
    FactoryBot.build(:private_collection_lw,
                     id: 'col-8-mgr',
                     title: ['bar for you'],
                     user: user2,
                     with_permission_template: { manage_users: [user1] },
                     with_solr_document: true)
  end

  let!(:collection9) do
    FactoryBot.build(:private_collection_lw,
                     title: ['bar too'],
                     user: user2,
                     with_permission_template: { deposit_users: [user1] },
                     with_solr_document: true)
  end

  let!(:collection10) do
    FactoryBot.build(:private_collection_lw,
                     title: ['bar bar baz'],
                     user: user2,
                     with_permission_template: { view_users: [user1] },
                     with_solr_document: true)
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
