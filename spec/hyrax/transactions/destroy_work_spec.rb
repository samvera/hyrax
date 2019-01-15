# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::DestroyWork do
  subject(:transaction) { described_class.new }
  let(:work)            { create(:generic_work) }

  describe '#call' do
    it 'is a success' do
      expect(transaction.call(work)).to be_success
    end

    it 'destroys the work' do
      expect { transaction.call(work) }
        .to change { work.persisted? }
        .from(true)
        .to false
    end

    context 'with an unsaved work' do
      let(:work) { build(:generic_work) }

      it 'is a success' do
        expect(transaction.call(work)).to be_success
      end

      it 'leaves the work unpersisted' do
        expect { transaction.call(work) }
          .not_to change { work.persisted? }
          .from false
      end
    end
  end
end
