# frozen_string_literal: true

RSpec.describe Hyrax::CompoundEntryValidation do
  # A definition shaped like Hyrax::CompoundSchema#definition_for produces.
  def build_definition(required: false, subproperties: {})
    { required: required, subproperties: subproperties }
  end

  def sub(required: false)
    { type: 'string', required: required }
  end

  describe 'a compound with no required sub-properties and not required itself' do
    let(:definition) { build_definition(subproperties: { 'a' => sub, 'b' => sub }) }

    it 'is valid with no rows' do
      expect(described_class.new(definition, []).violations).to be_empty
    end

    it 'is valid with a partially-filled row' do
      expect(described_class.new(definition, [{ 'a' => 'x' }]).violations).to be_empty
    end
  end

  describe 'a compound with required sub-properties (optional compound)' do
    let(:definition) { build_definition(subproperties: { 'item' => sub(required: true), 'type' => sub(required: true), 'note' => sub }) }

    it 'is valid with no rows (compound itself is optional)' do
      expect(described_class.new(definition, []).violations).to be_empty
    end

    it 'is valid when every populated row fills all required sub-properties' do
      entries = [{ 'item' => 'a', 'type' => 't' }, { 'item' => 'b', 'type' => 't', 'note' => 'n' }]
      expect(described_class.new(definition, entries).violations).to be_empty
    end

    it 'flags a row missing a required sub-property' do
      violations = described_class.new(definition, [{ 'item' => 'a' }]).violations
      expect(violations).to contain_exactly(type: :missing_required_subproperties, missing: ['type'])
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
    let(:definition) { build_definition(required: true, subproperties: { 'a' => sub(required: true) }) }

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

  describe 'a compound declaring an ordered rule' do
    let(:definition) do
      build_definition(subproperties: { 'start' => sub, 'finish' => sub })
        .merge(validations: [{ type: 'ordered', before: 'start', after: 'finish' }])
    end

    def violations_for(rows)
      described_class.new(definition, rows).violations
    end

    it 'is valid when the fields are in order' do
      expect(violations_for([{ 'start' => '2026-01-01', 'finish' => '2026-06-30' }])).to be_empty
    end

    it 'is valid when the two values are equal' do
      expect(violations_for([{ 'start' => '2026-01-01', 'finish' => '2026-01-01' }])).to be_empty
    end

    it 'is valid when the later field is blank' do
      expect(violations_for([{ 'start' => '2026-01-01' }])).to be_empty
    end

    it 'flags a row whose values are reversed' do
      expect(violations_for([{ 'start' => '2026-06-30', 'finish' => '2026-01-01' }]))
        .to contain_exactly(type: :out_of_order, missing: ['finish'])
    end

    # One message however many rows are wrong, as with missing_required_subproperties.
    it 'reports the rule once when several rows are reversed' do
      rows = [{ 'start' => '2026-06-30', 'finish' => '2026-01-01' },
              { 'start' => '2025-06-30', 'finish' => '2025-01-01' }]

      expect(violations_for(rows).count { |v| v[:type] == :out_of_order }).to eq(1)
    end

    it 'ignores values it cannot compare' do
      expect(violations_for([{ 'start' => 'circa 1920', 'finish' => 'later' }])).to be_empty
    end

    it 'defers to a missing required sub-property rather than reporting both' do
      required = build_definition(subproperties: { 'start' => sub(required: true), 'finish' => sub })
                 .merge(validations: [{ type: 'ordered', before: 'start', after: 'finish' }])

      expect(described_class.new(required, [{ 'finish' => '2026-01-01' }]).violations)
        .to contain_exactly(type: :missing_required_subproperties, missing: ['start'])
    end
  end

  describe 'a compound with no validations declared' do
    it 'applies no ordering rule' do
      definition = build_definition(subproperties: { 'start' => sub, 'finish' => sub })

      expect(described_class.new(definition, [{ 'start' => 'z', 'finish' => 'a' }]).violations).to be_empty
    end
  end

  describe '#valid?' do
    it 'is true when there are no violations' do
      expect(described_class.new(build_definition(subproperties: { 'a' => sub }), []).valid?).to be true
    end
  end
end
