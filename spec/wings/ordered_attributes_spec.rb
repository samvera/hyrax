# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/ordered_attributes'

RSpec.describe Wings::OrderedAttributes do
  let(:resource_class) do
    Class.new(Hyrax::Resource) do
      attribute :rows, Valkyrie::Types::Array.of(Dry::Types['hash']).meta(ordered: true)
      attribute :tags, Valkyrie::Types::Array.of(Dry::Types['hash'])
    end
  end

  describe '.encode' do
    it "records each entry's position in an ordered hash attribute" do
      encoded = described_class.encode({ rows: [{ 'name' => 'A' }, { name: 'B' }] }, resource_class)
      expect(encoded[:rows]).to eq [{ 'name' => 'A', '_position' => 0 }, { name: 'B', '_position' => 1 }]
    end

    it 'leaves an attribute that is not ordered unchanged' do
      attributes = { tags: [{ 'name' => 'A' }, { 'name' => 'B' }] }
      expect(described_class.encode(attributes, resource_class)).to eq attributes
    end
  end

  describe '.decode' do
    it 'restores the saved order of an ordered hash attribute and drops the positions' do
      stored = { rows: ['{"name":"B","_position":1}', '{"name":"C","_position":2}', '{"name":"A","_position":0}'] }
      expect(described_class.decode(stored, resource_class)[:rows])
        .to eq [{ 'name' => 'A' }, { 'name' => 'B' }, { 'name' => 'C' }]
    end

    it 'leaves an attribute that is not ordered unchanged' do
      stored = { tags: ['{"name":"B"}', '{"name":"A"}'] }
      expect(described_class.decode(stored, resource_class)).to eq stored
    end
  end
end
