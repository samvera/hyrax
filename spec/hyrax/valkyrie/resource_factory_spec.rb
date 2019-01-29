# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/valkyrie/resource_factory'

RSpec.describe Hyrax::Valkyrie::ResourceFactory do
  subject(:factory) { described_class.new(pcdm_object: work) }
  let(:adapter)     { Valkyrie::MetadataAdapter.find(:memory) }
  let(:id)          { 'moomin123' }
  let(:persister)   { adapter.persister }
  let(:work)        { GenericWork.new(id: id, **attributes) }

  let(:uris) do
    [RDF::URI('http://example.com/fake1'),
     RDF::URI('http://example.com/fake2')]
  end

  let(:attributes) do
    {
      title: ['fake title'],
      date_created: [Time.now.utc],
      depositor: 'user1',
      description: ['a description'],
      import_url: uris.first,
      related_url: uris
    }
  end

  before(:context) do
    Valkyrie::MetadataAdapter.register(
      Valkyrie::Persistence::Memory::MetadataAdapter.new,
      :memory
    )

    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Memory.new,
      :memory
    )
  end

  # TODO: extract to Valkyrie?
  define :have_a_valkyrie_id_of do |expected_id_str|
    match do |valkyrie_resource|
      expect(valkyrie_resource.id).to be_a Valkyrie::ID
      valkyrie_resource.id.id == expected_id_str
    end
  end

  describe '.for' do
    it 'returns a Valkyrie::Resource' do
      expect(described_class.for(work)).to be_a Valkyrie::Resource
    end
  end

  describe '#build' do
    it 'returns a Valkyrie::Resource' do
      expect(factory.build).to be_a Valkyrie::Resource
    end

    it 'has the id of the pcdm_object' do
      expect(factory.build).to have_a_valkyrie_id_of work.id
    end

    it 'has attributes matching the pcdm_object' do
      expect(factory.build)
        .to have_attributes title: work.title,
                            date_created: work.date_created,
                            depositor: work.depositor,
                            description: work.description
    end

    it 'round trips attributes' do
      persister.save(resource: factory.build)

      expect(adapter.query_service.find_by(id: work.id))
        .to have_attributes title: work.title,
                            date_created: work.date_created,
                            depositor: work.depositor,
                            description: work.description,
                            import_url: work.import_url,
                            related_url: work.related_url
    end
  end
end
