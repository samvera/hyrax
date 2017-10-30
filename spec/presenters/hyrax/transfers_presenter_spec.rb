RSpec.describe Hyrax::TransfersPresenter do
  let(:context) { ActionView::TestCase::TestController.new.view_context }
  let(:user) { create(:user) }
  let(:instance) { described_class.new(user, context) }

  describe "#incoming_proxy_deposits" do
    subject(:incoming_proxy_deposits) { instance.send(:incoming_proxy_deposits) }

    let(:another_user) { create(:user) }
    let!(:incoming_work) do
      create_for_repository(:work, user: another_user).tap do |w|
        w.request_transfer_to(user)
      end
    end

    it 'returns a list of ProxyDepositRequests' do
      expect(incoming_proxy_deposits.first).to be_kind_of ProxyDepositRequest
      expect(incoming_proxy_deposits.first.work_id).to eq(incoming_work.id.to_s)
    end

    context "When the incoming request is for a deleted work" do
      before do
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        persister.delete(resource: incoming_work)
      end
      it "does not show that work" do
        expect(incoming_proxy_deposits).to be_empty
      end
    end
  end

  describe "#outgoing_proxy_deposits" do
    subject { instance.send(:outgoing_proxy_deposits) }

    let(:another_user) { create(:user) }
    let!(:outgoing_work) do
      create_for_repository(:work, user: user).tap do |w|
        w.request_transfer_to(another_user)
      end
    end

    it 'returns a list of ProxyDepositRequests' do
      expect(subject.first).to be_kind_of ProxyDepositRequest
      expect(subject.first.work_id).to eq(outgoing_work.id.to_s)
    end
  end
end
