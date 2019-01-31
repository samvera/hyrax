# frozen_string_literal: true
require 'spec_helper'
require 'wings/metadata_adapter'
require 'wings/query_service'

RSpec.describe Wings::QueryService do
  let(:query_service) { described_class.new(adapter: adapter, resource_factory: resource_factory) }
  let(:adapter) { Wings::MetadataAdapter.new }
  let(:resource_factory) { Wings::Valkyrie::ResourceFactory.new(adapter: adapter) }

  # it_behaves_like "a Valkyrie query provider"
  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by)
  end
end
