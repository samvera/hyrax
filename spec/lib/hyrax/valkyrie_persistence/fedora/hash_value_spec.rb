# frozen_string_literal: true

require 'valkyrie/persistence/fedora'

RSpec.describe Hyrax::ValkyriePersistence::Fedora::HashValue do
  let(:adapter) do
    Valkyrie::Persistence::Fedora::MetadataAdapter.new(connection: Ldp::Client.new(Faraday.new('http://fedora.invalid/rest')),
                                                       base_path: 'test')
  end
  let(:resource_class) do
    Class.new(Valkyrie::Resource) do
      attribute :aliases, Valkyrie::Types::Array.of(Valkyrie::Types::Anything)
    end
  end
  let(:resource) { resource_class.new(id: 'abc', aliases: aliases) }
  let(:objects) do
    converter = Valkyrie::Persistence::Fedora::Persister::ModelConverter
    property = converter::Property.new(RDF::URI('http://fedora.invalid/rest/test/abc'), :aliases, aliases, adapter, resource)
    graph = converter::FedoraValue.for(property).result.to_graph
    graph.query([nil, property.predicate, nil]).map(&:object)
  end

  context 'with plain hash entries' do
    let(:aliases) { [{ 'path' => '/one', 'is_display_url' => true }, { path: '/two' }] }

    it 'writes each entry as one JSON literal typed valkyrie_hash' do
      expect(objects.map(&:to_s))
        .to contain_exactly('{"path":"/one","is_display_url":true}', '{"path":"/two"}')
      expect(objects.map(&:datatype).uniq).to eq [Valkyrie::Persistence::Fedora::PermissiveSchema.uri_for(:valkyrie_hash)]
    end
  end

  context 'with a nested resource entry' do
    let(:aliases) { [{ internal_resource: 'Hyrax::Permission', agent: 'group/public' }] }

    it 'leaves it to the nested-resource mapper' do
      expect(objects).to all(be_a(RDF::URI))
    end
  end

  describe 'reading a valkyrie_hash literal' do
    let(:aliases) { [] }

    it 'returns the JSON as a plain string' do
      orm = Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes
      literal = RDF::Literal.new('{"path":"/one","is_display_url":true}',
                                 datatype: Valkyrie::Persistence::Fedora::PermissiveSchema.uri_for(:valkyrie_hash))
      statement = RDF::Statement.new(RDF::URI('http://fedora.invalid/rest/test/abc'), RDF::URI('http://example.com/aliases'), literal)
      attributes = {}
      orm::FedoraValue.for(orm::Property.new(statement: statement, scope: RDF::Graph.new, adapter: adapter)).result.apply_to(attributes)

      expect(attributes.values.flatten).to eq ['{"path":"/one","is_display_url":true}']
    end
  end
end
