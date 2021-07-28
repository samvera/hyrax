# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::FileSetDestroy do
  subject(:transaction) { described_class.new }
  let(:file_set)        { FactoryBot.valkyrie_create(:hyrax_file_set) }

  describe '#call' do
    let(:user) { FactoryBot.create(:user) }

    context 'without a user' do
      it 'is a failure' do
        expect(transaction.call(file_set)).to be_failure
      end
    end

    it 'succeeds' do
      expect(transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set))
        .to be_success
    end

    it 'deletes the file set' do
      transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set)

      expect { Hyrax.query_service.find_by(id: file_set.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
