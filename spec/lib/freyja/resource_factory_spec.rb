# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'wings'
require 'freyja/metadata_adapter'

RSpec.describe Freyja::ResourceFactory, :active_fedora do
  subject(:factory) { described_class.new(adapter: adapter) }
  let(:adapter)     { Freyja::MetadataAdapter.new }
  let(:work)        { GenericWork.new }

  describe '#from_resource' do
    let(:resource) { work.valkyrie_resource }

    it 'returns an Valkyrie Postgres object' do
      expect(factory.from_resource(resource: resource)).to be_a Valkyrie::Persistence::Postgres::ORM::Resource
    end
  end
end
