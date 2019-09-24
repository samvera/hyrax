# frozen_string_literal: true
require 'spec_helper'
require 'wings'

RSpec.describe Wings::Valkyrie::ResourceFactory do
  subject(:factory) { described_class.new(adapter: adapter) }
  let(:adapter)     { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:work)        { GenericWork.new }

  describe '#to_resource' do
    it 'returns a valkyrie_resource for the object' do
      expect(factory.to_resource(object: work)).to be_a Valkyrie::Resource
    end
  end

  describe '#from_resource' do
    let(:resource) { work.valkyrie_resource }

    it 'returns an ActiveFedora object' do
      expect(factory.from_resource(resource: resource)).to be_a GenericWork
    end

    context 'with a FileSet' do
      let(:resource) { file_set.valkyrie_resource }
      let(:file_set) { FileSet.new }

      it 'returns an ActiveFedora object' do
        expect(factory.from_resource(resource: resource)).to be_a FileSet
      end
    end
  end

  describe 'round trip starting from unsaved af object' do
    let(:work) { build(:work) }
    let(:resource) { factory.to_resource(object: work).save }
    it 'allows af object to be reloaded' do
      expect(work.reload.id).to eq resource.alternate_id.to_s
    end
  end
end
