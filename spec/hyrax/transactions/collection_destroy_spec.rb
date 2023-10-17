# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::CollectionDestroy, valkyrie_adapter: :test_adapter do
  subject(:tx)   { described_class.new }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:user)         { FactoryBot.create(:user) }

  describe '#call' do
    it 'is a success' do
      expect(
        tx
          .with_step_args('collection_resource.delete' => { user: user },
                          'collection_resource.remove_from_membership' => { user: user })
          .call(resource)
      ).to be_success
    end
  end
end
