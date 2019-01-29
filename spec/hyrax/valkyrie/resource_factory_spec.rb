# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/valkyrie/resource_factory'

RSpec.describe Hyrax::Valkyrie::ResourceFactory do
  subject(:factory) { described_class.new(pcdm_object: work) }
  let(:id)          { 'moomin123' }
  let(:work)        { GenericWork.new(id: id, **attributes) }

  let(:attributes) do
    {
      title: ['fake title'],
      depositor: 'user1',
      description: ['a description']
    }
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
                            depositor: work.depositor,
                            description: work.description
    end
  end
end
