# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Indexers::AdministrativeSetIndexer do
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_admin_set) }
  let(:indexer_class) { described_class }

  it_behaves_like 'an Administrative Set indexer'

  subject(:service) { described_class.new(resource: admin_set) }
  let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set, title: [admin_set_title]) }
  let(:admin_set_title) { 'An Admin Set' }

  it 'is resolved from an admin set' do
    expect(Hyrax::Indexers::ResourceIndexer.for(resource: resource))
      .to be_a described_class
  end
end
