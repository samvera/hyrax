# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SaveWork do
  subject(:step) { described_class.new }
  let(:work)     { build(:generic_work) }

  describe '#call' do
    it 'is success' do
      expect(step.call(work)).to be_success
    end

    it 'persists the work' do
      expect { step.call(work) }
        .to change { work.persisted? }
        .to true
    end

    context 'if the work is invalid' do
      let(:work) { build(:invalid_generic_work) }

      it 'returns failure' do
        expect(step.call(work)).to be_failure
      end

      it 'gives errors about the work' do
        expect(step.call(work).failure).to eq work.errors
      end
    end
  end
end
