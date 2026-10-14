# frozen_string_literal: true

RSpec.describe 'Persisting a hash-typed schema attribute through the configured metadata adapter', :clean_repo do
  before do
    class HashAttributeResource < Hyrax::Resource; end
    config = { 'type' => 'hash', 'multiple' => true }
    HashAttributeResource.attribute :aliases, Hyrax::SchemaLoader::AttributeDefinition.new('aliases', config).type.meta(config)
    HashAttributeResource.attribute :untyped
  end
  after { Object.send(:remove_const, :HashAttributeResource) }

  def round_trip(entries)
    saved = Hyrax.persister.save(resource: HashAttributeResource.new(aliases: entries))
    Hyrax.query_service.find_by(id: saved.id).aliases.map { |entry| entry.transform_keys(&:to_s) }
  end

  it 'reloads multi-key entries with each value still paired to its entry' do
    entries = [{ 'path' => '/one', 'is_display_url' => true },
               { 'path' => '/two', 'is_display_url' => false }]

    expect(round_trip(entries)).to contain_exactly(*entries)
  end

  it 'reloads single-key entries as separate entries' do
    entries = [{ 'name' => 'Ada' }, { 'role' => 'Editor' }]

    expect(round_trip(entries)).to contain_exactly(*entries)
  end

  it 'reloads entries in the order they were saved' do
    entries = (1..6).map { |i| { 'name' => "person-#{i}", 'role' => 'Author' } }

    expect(round_trip(entries)).to eq entries
  end

  it 'reloads an empty list as empty' do
    expect(round_trip([])).to eq []
  end

  it 'reloads arrays inside an entry in order, keeping one-element and empty arrays' do
    entries = [{ 'name' => 'Ada', 'tags' => %w[b a c], 'roles' => ['Author'], 'notes' => [] }]

    expect(round_trip(entries)).to eq entries
  end

  it 'drops nil values from an entry' do
    skip 'Wings stores a hash as a JSON string, which keeps nil values' if defined?(Wings::Valkyrie::MetadataAdapter) && Hyrax.metadata_adapter.is_a?(Wings::Valkyrie::MetadataAdapter)

    expect(round_trip([{ 'name' => 'Ada', 'note' => nil }])).to eq [{ 'name' => 'Ada' }]
  end

  it 'still rebuilds typed values in a hash stored in an untyped attribute' do
    skip 'Wings stores a hash as a JSON string that only a hash type parses' if defined?(Wings::Valkyrie::MetadataAdapter) && Hyrax.metadata_adapter.is_a?(Wings::Valkyrie::MetadataAdapter)
    entry = { ref: Valkyrie::ID.new('abc'), name: 'Ada' }
    saved = Hyrax.persister.save(resource: HashAttributeResource.new(untyped: [entry]))

    expect(Hyrax.query_service.find_by(id: saved.id).untyped).to eq [entry]
  end
end
