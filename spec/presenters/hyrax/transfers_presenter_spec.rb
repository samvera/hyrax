# frozen_string_literal: true
RSpec.describe Hyrax::TransfersPresenter do
  let(:context) { ActionView::TestCase::TestController.new.view_context }
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:instance) { described_class.new(user, context) }

  describe "#incoming_proxy_deposits" do
    subject(:incoming_proxy_deposits) { instance.send(:incoming_proxy_deposits) }

    let!(:incoming_work) do
      if Hyrax.config.use_valkyrie?
        valkyrie_create(:hyrax_work, depositor: another_user.user_key)
      else
        create(:work, user: another_user)
      end
    end

    before do
      if Hyrax.config.use_valkyrie?
        ProxyDepositRequest.create!(work_id: incoming_work.id, receiving_user: user, sending_user: another_user)
      else
        incoming_work.request_transfer_to(user)
      end
    end

    it 'returns a list of ProxyDepositRequests' do
      expect(incoming_proxy_deposits.first).to be_kind_of ProxyDepositRequest
      expect(incoming_proxy_deposits.first.work_id).to eq(incoming_work.id)
    end

    context "When the incoming request is for a deleted work" do
      before do
        if Hyrax.config.use_valkyrie?
          transaction = Hyrax::Transactions::WorkDestroy.new
          transaction.with_step_args('work_resource.delete_all_file_sets' => { user: another_user }).call(incoming_work)
        else
          incoming_work.destroy
        end
      end

      it "does not show that work" do
        expect(incoming_proxy_deposits).to be_empty
      end
    end
  end

  describe "#outgoing_proxy_deposits" do
    subject { instance.send(:outgoing_proxy_deposits) }

    let!(:outgoing_work) do
      if Hyrax.config.use_valkyrie?
        valkyrie_create(:hyrax_work, depositor: user.user_key)
      else
        create(:work, user: user)
      end
    end

    before do
      if Hyrax.config.use_valkyrie?
        ProxyDepositRequest.create!(work_id: outgoing_work.id, receiving_user: another_user, sending_user: user)
      else
        outgoing_work.request_transfer_to(another_user)
      end
    end

    it 'returns a list of ProxyDepositRequests' do
      expect(subject.first).to be_kind_of ProxyDepositRequest
      expect(subject.first.work_id).to eq(outgoing_work.id)
    end
  end
end
