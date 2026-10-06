# frozen_string_literal: true

RSpec.describe 'Persisting a hash-typed schema attribute through the configured metadata adapter', :clean_repo do
  before do
    class HashAttributeResource < Hyrax::Resource; end
    config = { 'type' => 'hash', 'multiple' => true }
    HashAttributeResource.attribute :aliases, Hyrax::SchemaLoader::AttributeDefinition.new('aliases', config).type.meta(config)
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
end
