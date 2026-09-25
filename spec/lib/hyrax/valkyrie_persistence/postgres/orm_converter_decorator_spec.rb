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

  context 'with a row that already stores splayed [key, value] pairs' do
    before do
      class HashAttributeResource < Hyrax::Resource; end
      config = { 'type' => 'hash', 'multiple' => true }
      HashAttributeResource.attribute :aliases, Hyrax::SchemaLoader::AttributeDefinition.new('aliases', config).type.meta(config)
    end
    after { Object.send(:remove_const, :HashAttributeResource) if defined?(HashAttributeResource) }

    def reload_with_stored(json)
      id = Hyrax.persister.save(resource: HashAttributeResource.new(aliases: [{ 'path' => '/x' }])).id
      ActiveRecord::Base.connection.execute(
        "UPDATE orm_resources SET metadata = jsonb_set(metadata, '{aliases}', '#{json}'::jsonb) WHERE id = '#{id}'"
      )
      Hyrax::Current.reset
      Hyrax.query_service.find_by(id: id).aliases.map { |entry| entry.transform_keys(&:to_s) }
    end

    it 'loads a stored single pair as one entry' do
      expect(reload_with_stored('["path", "/solo"]')).to eq [{ 'path' => '/solo' }]
    end

    it 'loads stored pairs with a repeated key as one entry each' do
      expect(reload_with_stored('[["path", "/a"], ["path", "/b"]]')).to eq [{ 'path' => '/a' }, { 'path' => '/b' }]
    end
  end
end
