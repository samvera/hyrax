# frozen_string_literal: true
RSpec.describe Qa::Authorities::Collections, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:q) { "foo" }
  let(:service) { described_class.new }
  let!(:collection1) { build(:private_collection_lw, id: 'col-1-own', title: ['foo foo'], user: user1, with_permission_template: true, with_solr_document: true) }
  let!(:collection2) { build(:private_collection_lw, id: 'col-2-own', title: ['bar'], user: user1, with_permission_template: true, with_solr_document: true) }
  let!(:collection3) { build(:private_collection_lw, id: 'col-3-own', title: ['another foo'], user: user1, with_permission_template: true, with_solr_document: true) }
  let!(:collection4) { build(:private_collection_lw, id: 'col-4-none', title: ['foo foo foo'], user: user2, with_permission_template: true, with_solr_document: true) }
  let!(:collection5) do
    build(:private_collection_lw, id: 'col-5-mgr', title: ['foo for you'], user: user2,
                                  with_permission_template: { manage_users: [user1] }, with_solr_document: true)
  end
  let!(:collection6) do
    build(:private_collection_lw, id: 'col-6-dep', title: ['foo too'], user: user2,
                                  with_permission_template: { deposit_users: [user1] }, with_solr_document: true)
  end
  let!(:collection7) do
    build(:private_collection_lw, id: 'col-7-view', title: ['foo bar baz'], user: user2,
                                  with_permission_template: { view_users: [user1] }, with_solr_document: true)
  end
  let!(:collection8) do
    build(:private_collection_lw, id: 'col-8-mgr', title: ['bar for you'], user: user2,
                                  with_permission_template: { manage_users: [user1] }, with_solr_document: true)
  end
  let!(:collection9) do
    build(:private_collection_lw, id: 'col-9-dep', title: ['bar too'], user: user2,
                                  with_permission_template: { deposit_users: [user1] }, with_solr_document: true)
  end
  let!(:collection10) do
    build(:private_collection_lw, id: 'col-10-view', title: ['bar bar baz'], user: user2,
                                  with_permission_template: { view_users: [user1] }, with_solr_document: true)
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
