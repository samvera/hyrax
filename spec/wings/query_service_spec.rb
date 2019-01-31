# frozen_string_literal: true
require 'spec_helper'
require 'wings/metadata_adapter'
require 'wings/query_service'

RSpec.describe Wings::QueryService do
  let(:subject) { described_class.new(adapter: adapter, resource_factory: factory) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:memory) }
  let(:persister)   { adapter.persister }

  let(:work)        { GenericWork.new(id: id, **attributes) }
  let(:id)          { 'moomin123' }
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

  let(:factory) { Wings::Resource_Factory.new(pcdm_object: work) }

  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by)
  end

  describe '.find_by' do
    before do
      persister.save
    end

    expect(subject.find_by(id: work.id).to_return(work.to_valkyrie_resource)
  end
end
