# frozen_string_literal: true

RSpec.describe 'Reading a plain Hash stored in the earlier nested-graph format', :clean_repo do
  before do
    skip 'requires the Valkyrie Fedora metadata adapter' unless Hyrax.metadata_adapter.is_a?(Valkyrie::Persistence::Fedora::MetadataAdapter)
    class LegacyHashResource < Hyrax::Resource
      attribute :legacy, Valkyrie::Types::Array.of(Valkyrie::Types::Anything).meta(ordered: true)
    end
  end
  after { Object.send(:remove_const, :LegacyHashResource) if defined?(LegacyHashResource) }

  # Saving a nested resource whose class is named after the old marker writes
  # the same graph the earlier format did.
  def save_in_legacy_format(path)
    Valkyrie.const_set(:InternalHash, Class.new(Valkyrie::Resource) { attribute :path, Valkyrie::Types::String })
    legacy_hash = Valkyrie::InternalHash.new(path: path, internal_resource: 'Valkyrie::InternalHash')
    Hyrax.persister.save(resource: LegacyHashResource.new(legacy: [legacy_hash]))
  ensure
    Valkyrie.send(:remove_const, :InternalHash) if Valkyrie.const_defined?(:InternalHash, false)
  end

  it 'reads the Hash back as its own keys' do
    saved = save_in_legacy_format('/old')

    expect(Hyrax.query_service.find_by(id: saved.id).legacy).to eq [{ path: '/old' }]
  end

  it 'reads an empty RDF list (rdf:nil) inside the Hash back as an empty array' do
    saved = save_in_legacy_format(RDF.nil)

    expect(Hyrax.query_service.find_by(id: saved.id).legacy).to eq [{ path: [] }]
  end
end
