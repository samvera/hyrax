# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::DeleteAllFileMetadata, valkyrie_adapter: :test_adapter, storage_adapter: :test_disk do
  subject(:step) { described_class.new }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :with_files) }

  describe '#call' do
    it 'gives success' do
      expect(step.call(file_set)).to be_success
    end

    it 'destroys each file_set' do
      file_ids = file_set.file_ids
      step.call(file_set)
      file_ids.each do |id|
        expect { Hyrax.query_service.find_by(id: id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'with a resource that is not saved' do
      let(:file_set) { FactoryBot.build(:hyrax_file_set) }

      it 'is a failure' do
        expect(step.call(file_set)).to be_failure
      end
    end
  end
end
