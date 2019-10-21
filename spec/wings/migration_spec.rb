# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'migrating Valkyrie adapters' do
  let(:test)  { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:wings) { Valkyrie::MetadataAdapter.find(:wings_adapter) }

  before do
    test.persister.wipe!
    wings.persister.wipe!
  end

  it do
    10.times  { FactoryBot.valkyrie_create(:hyrax_work) }

    wings.query_service.find_all.each do |resource|
      test.persister.save(resource: resource)
    end

    expect(test.query_service.find_all.map(&:id))
      .to contain_exactly(*wings.query_service.find_all.map(&:id))
  end
end
