RSpec.describe Qa::Authorities::Collections, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:q) { "foo" }
  let(:service) { described_class.new }
  let!(:collection1) { create(:private_collection, id: 'col-1-own', title: ['foo foo'], user: user1, create_access: true) }
  let!(:collection2) { create(:private_collection, id: 'col-2-own', title: ['bar'], user: user1, create_access: true) }
  let!(:collection3) { create(:private_collection, id: 'col-3-own', title: ['another foo'], user: user1, create_access: true) }
  let!(:collection4) { create(:private_collection, id: 'col-4-none', title: ['foo foo foo'], user: user2, create_access: true) }
  let!(:collection5) do
    create(:private_collection, id: 'col-5-mgr', title: ['foo for you'], user: user2,
                                with_permission_template: { manage_users: [user1] }, create_access: true)
  end
  let!(:collection6) do
    create(:private_collection, id: 'col-6-dep', title: ['foo too'], user: user2,
                                with_permission_template: { deposit_users: [user1] }, create_access: true)
  end
  let!(:collection7) do
    create(:private_collection, id: 'col-7-view', title: ['foo bar baz'], user: user2,
                                with_permission_template: { view_users: [user1] }, create_access: true)
  end
  let!(:collection8) do
    create(:private_collection, id: 'col-8-mgr', title: ['bar for you'], user: user2,
                                with_permission_template: { manage_users: [user1] }, create_access: true)
  end
  let!(:collection9) do
    create(:private_collection, id: 'col-9-dep', title: ['bar too'], user: user2,
                                with_permission_template: { deposit_users: [user1] }, create_access: true)
  end
  let!(:collection10) do
    create(:private_collection, id: 'col-10-view', title: ['bar bar baz'], user: user2,
                                with_permission_template: { view_users: [user1] }, create_access: true)
  end

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
  end

  subject { service.search(q, controller) }

  describe '#search' do
    context 'when access is read' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'read') }

      it 'displays a list of read collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [collection1.id, collection3.id, collection5.id, collection6.id, collection7.id]
      end
    end

    context 'when access is edit' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'edit') }

      it 'displays a list of edit collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [collection1.id, collection3.id, collection5.id]
      end
    end

    context 'when access is deposit' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'deposit') }

      it 'displays a list of edit and deposit collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [collection1.id, collection3.id, collection5.id, collection6.id]
      end
    end
  end
end
