# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ChangeContentDepositor, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  it 'gives Success(obj) in basic case' do
    expect(step.call(work).value!).to eql(work)
  end

  context "when the depositor update is successful" do
    it "calls the service" do
      allow(Hyrax::ChangeContentDepositorService).to receive(:call)
      step.call(work)

      expect(Hyrax::ChangeContentDepositorService).to have_received(:call)
    end
  end

  context "when there's an error" do
    it 'returns a Failure' do
      allow(Hyrax::ChangeContentDepositorService).to receive(:call).and_raise
      result = step.call(work)

      expect(result).to be_failure
    end
  end
end
