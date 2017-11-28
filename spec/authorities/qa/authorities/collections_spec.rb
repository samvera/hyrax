RSpec.describe Qa::Authorities::Collections, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:q) { "foo" }
  let(:params) { ActionController::Parameters.new(q: q, access: 'edit') }
  let(:service) { described_class.new }
  let!(:collection1) { create(:collection, :public, title: ['foo foo'], user: user1) }
  let!(:collection2) { create(:collection, :public, title: ['bar'], user: user1) }
  let!(:collection3) { create(:collection, :public, title: ['another foo'], user: user1) }
  let!(:collection4) { create(:collection, :public, title: ['foo foo foo'], user: user2) }

  before do
    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
  end

  subject { service.search(q, controller) }

  describe '#search' do
    it 'displays a list of collections for the current user' do
      expect(subject.map { |result| result[:id] }).to match_array [collection1.id, collection3.id]
    end
  end
end
