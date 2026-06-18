# frozen_string_literal: true

# A `linked_record` compound sub-property stores its reference (a row id/key) as
# a plain string at the Valkyrie layer — the same as `string`, and the same way
# `work_or_url` is effectively a string. The schema loader's type resolution
# must recognize `linked_record` and resolve it to the string member type;
# without the case it falls through to the classify branch and raises
# ArgumentError ("Unrecognized type: linked_record").
RSpec.describe Hyrax::SchemaLoader::AttributeDefinition do
  let(:string_member_type) do
    described_class.new('ref', { 'type' => 'string' }).send(:type_for, 'string')
  end

  describe '#type_for with a linked_record type' do
    subject(:linked_record_type) do
      described_class.new('ref', { 'type' => 'linked_record' }).send(:type_for, 'linked_record')
    end

    it 'does not raise' do
      expect { linked_record_type }.not_to raise_error
    end

    it 'resolves to the same member type as a string (stored as a string reference)' do
      expect(linked_record_type).to eq(string_member_type)
    end
  end

  describe '#type for a linked_record attribute' do
    it 'builds without raising' do
      definition = described_class.new('ref', { 'type' => 'linked_record' })
      expect { definition.type }.not_to raise_error
    end
  end
end
