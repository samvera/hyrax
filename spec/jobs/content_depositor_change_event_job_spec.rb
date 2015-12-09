require 'spec_helper'

describe ContentDepositorChangeEventJob do
  let!(:receiver) { create(:user) }
  let!(:work) { mock_model("MockWork", id: "1234", proxy_depositor: receiver, title: ["Title"]) }

  before do
    allow_any_instance_of(described_class).to receive(:work).and_return(work)
    allow_any_instance_of(described_class).to receive(:proxy_depositor).and_return(receiver)
  end
  it "logs the event" do
    expect(work).to receive(:log_event)
    described_class.perform_now(work.id, receiver.user_key)
  end
end
