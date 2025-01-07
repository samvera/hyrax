# frozen_string_literal: true
RSpec.describe Qa::Authorities::FindWorks, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user1) }
  let(:q) { "foo" }
  let(:params) { ActionController::Parameters.new(q: q, id: work1.id.id, user: user1.user_key, controller: "qa/terms", action: "search", vocab: "find_works") }
  let(:service) { described_class.new }
  let!(:work1) { valkyrie_create(:monograph, :public, title: ['foo'], depositor: user1.user_key, edit_users: [user1]) }
  let!(:work2) { valkyrie_create(:monograph, :public, title: ['foo foo'], depositor: user1.user_key, edit_users: [user1]) }
  let!(:work3) { valkyrie_create(:monograph, :public, title: ['bar'], depositor: user1.user_key, edit_users: [user1]) }
  let!(:work4) { valkyrie_create(:monograph, :public, title: ['another foo'], depositor: user1.user_key, edit_users: [user1]) }
  let!(:work5) { valkyrie_create(:monograph, :public, title: ['foo foo foo'], depositor: user2.user_key, edit_users: [user2]) }

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  subject { service.search(q, controller) }

  describe '#search' do
    context "works by all users" do
      it 'displays a list of other works deposited by current user' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id, work4.id]
      end
    end

    context "when work has child works" do
      before do
        work4.member_ids += [work1.id]
        Hyrax.persister.save(resource: work4)
        Hyrax.index_adapter.save(resource: work4)
      end

      it 'displays a list of other works deposited by current user, exluding the child work' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id]
      end
    end

    context "when work has parent works" do
      before do
        work1.member_ids += [work4.id]
        Hyrax.persister.save(resource: work1)
        Hyrax.index_adapter.save(resource: work1)
      end

      it 'displays a list of other works deposited by current user, excluding the parent work' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id]
      end
    end
  end
end
