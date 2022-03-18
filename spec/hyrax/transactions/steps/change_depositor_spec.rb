# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ChangeDepositor, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:user)     { create(:user) }

  it 'gives Success(obj) in basic case' do
    expect(step.call(work).value!).to eql(work)
  end

  context "when the depositor update is successful" do
    it "calls the service" do
      allow(Hyrax::ChangeDepositorService).to receive(:call).and_call_original
      result = step.call(work, user: user).value!
      expect(result.id).to eql(work.id)

      expect(Hyrax::ChangeDepositorService).to have_received(:call)
    end
  end

  context "when a nil user is passed" do
    let(:user) { nil }

    it "does not call the service" do
      allow(Hyrax::ChangeDepositorService).to receive(:call).and_call_original
      expect(step.call(work, user: nil).value!).to eql(work)

      expect(Hyrax::ChangeDepositorService).not_to have_received(:call)
    end
  end

  context "when there's an error" do
    it 'returns a Failure' do
      allow(Hyrax::ChangeDepositorService).to receive(:call).and_raise
      result = step.call(work, user: user)

      expect(result).to be_failure
    end
  end
end
