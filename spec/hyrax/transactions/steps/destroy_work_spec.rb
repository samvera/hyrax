# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::DestroyWork do
  subject(:step) { described_class.new }
  let(:work)     { build(:generic_work) }

  it 'is a success' do
    expect(step.call(work)).to be_success
  end

  context 'with an existing work' do
    let(:work) { create(:generic_work) }

    it 'destroys the work' do
      expect { step.call(work) }
        .to change { work.persisted? }
        .from(true)
        .to false
    end

    context 'when destruction fails for an unknown reason' do
      let(:message) { 'moomin message' }

      before { allow(work).to receive(:destroy).and_raise(message) }

      it 'is a failure' do
        expect(step.call(work).failure).to have_attributes(message: message)
      end
    end
  end
end
