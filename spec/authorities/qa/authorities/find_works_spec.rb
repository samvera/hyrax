RSpec.describe Qa::Authorities::FindWorks do
  before do
    persister.wipe!
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  let!(:work1) { create_for_repository(:work, :public, title: ['foo'], user: user1) }
  let!(:work2) { create_for_repository(:work, :public, title: ['foo foo'], user: user1) }
  let!(:work3) { create_for_repository(:work, :public, title: ['bar'], user: user1) }
  let!(:work4) { create_for_repository(:work, :public, title: ['another foo'], user: user1) }
  let!(:work5) { create_for_repository(:work, :public, title: ['foo foo foo'], user: user2) }
  let(:controller) { Qa::TermsController.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user1) }
  let(:q) { "foo" }
  let(:params) { ActionController::Parameters.new(q: q, id: work1.id.to_s, user: user1.email, controller: "qa/terms", action: "search", vocab: "find_works") }
  let(:service) { described_class.new }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

  subject { service.search(q, controller) }

  describe '#search' do
    context "works by all users" do
      it 'displays a list of other works deposited by current user' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id.to_s, work4.id.to_s]
      end
    end

    context "when work has child works" do
      before do
        work4.member_ids += [work1.id]
        persister.save(resource: work4)
      end

      it 'displays a list of other works deposited by current user, exluding the child work' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id]
      end
    end

    context "when work has parent works" do
      before do
        work1.member_ids += [work4.id]
        persister.save(resource: work1)
      end

      it 'displays a list of other works deposited by current user, excluding the parent work' do
        expect(subject.map { |result| result[:id] }).to match_array [work2.id]
      end
    end
  end
end
