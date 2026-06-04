# frozen_string_literal: true

RSpec.describe Hyrax::CompoundEntryValidation do
  # A definition shaped like Hyrax::CompoundSchema#definition_for produces.
  def build_definition(required: false, subfields: {})
    { required: required, subfields: subfields }
  end

  def sub(required: false)
    { type: 'string', required: required }
  end

  describe 'a compound with no required sub-fields and not required itself' do
    let(:definition) { build_definition(subfields: { 'a' => sub, 'b' => sub }) }

    it 'is valid with no rows' do
      expect(described_class.new(definition, []).violations).to be_empty
    end

    it 'is valid with a partially-filled row' do
      expect(described_class.new(definition, [{ 'a' => 'x' }]).violations).to be_empty
    end
  end

  describe 'a compound with required sub-fields (optional compound)' do
    let(:definition) { build_definition(subfields: { 'item' => sub(required: true), 'type' => sub(required: true), 'note' => sub }) }

    it 'is valid with no rows (compound itself is optional)' do
      expect(described_class.new(definition, []).violations).to be_empty
    end

    it 'is valid when every populated row fills all required sub-fields' do
      entries = [{ 'item' => 'a', 'type' => 't' }, { 'item' => 'b', 'type' => 't', 'note' => 'n' }]
      expect(described_class.new(definition, entries).violations).to be_empty
    end

    it 'flags a row missing a required sub-field' do
      violations = described_class.new(definition, [{ 'item' => 'a' }]).violations
      expect(violations).to contain_exactly(type: :missing_required_subfields, missing: ['type'])
    end

    it 'reports one violation per distinct missing-key set (deduped)' do
      entries = [{ 'item' => 'a' }, { 'item' => 'b' }] # both miss only `type`
      violations = described_class.new(definition, entries).violations
      expect(violations.size).to eq(1)
    end

    it 'accepts symbol-keyed rows' do
      expect(described_class.new(definition, [{ item: 'a', type: 't' }]).violations).to be_empty
    end
  end

  describe 'a required compound' do
    let(:definition) { build_definition(required: true, subfields: { 'a' => sub(required: true) }) }

    it 'flags an empty compound' do
      expect(described_class.new(definition, []).violations)
        .to contain_exactly(type: :required_but_empty, missing: ['a'])
    end

    it 'is valid with a complete row' do
      expect(described_class.new(definition, [{ 'a' => 'x' }]).violations).to be_empty
    end

    it 'flags an incomplete row rather than emptiness when a row is present' do
      violations = described_class.new(definition, [{ 'a' => '' }]).violations
      # an all-blank row is not "populated", so the compound reads as empty
      expect(violations).to contain_exactly(type: :required_but_empty, missing: ['a'])
    end
  end

  describe '#valid?' do
    it 'is true when there are no violations' do
      expect(described_class.new(build_definition(subfields: { 'a' => sub }), []).valid?).to be true
    end
  end
end
