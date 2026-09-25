# frozen_string_literal: true

RSpec.describe Hyrax::ValkyriePersistence::Postgres::ORMConverterDecorator, :clean_repo do
  before do
    skip 'requires the Postgres metadata adapter' unless Hyrax.metadata_adapter.is_a?(Valkyrie::Persistence::Postgres::MetadataAdapter)
    Hyrax::Current.reset
  end

  it 'resolves the hash attribute names once per resource class and schema version within a request' do
    allow(Hyrax::CompoundSchema).to receive(:for_stored_record).and_call_original
    ids = Array.new(2) { Hyrax.persister.save(resource: Hyrax::Work.new).id }

    ids.each { |id| Hyrax.query_service.find_by(id: id) }

    expect(Hyrax::CompoundSchema).to have_received(:for_stored_record).once
  end
end
