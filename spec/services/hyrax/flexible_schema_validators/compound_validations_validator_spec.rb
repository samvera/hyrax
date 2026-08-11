# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::CompoundValidationsValidator do
  subject(:validator) { described_class.new(profile, warnings) }

  let(:warnings) { [] }

  def compound(validations)
    { 'dates' => { 'type' => 'hash', 'validations' => validations } }
  end

  describe '#validate!' do
    it 'accepts a known rule' do
      profile = { 'properties' => compound([{ 'type' => 'ordered', 'before' => 'a', 'after' => 'b' }]) }
      described_class.new(profile, warnings).validate!

      expect(warnings).to be_empty
    end

    it 'warns on an unrecognized rule type, which would otherwise do nothing silently' do
      profile = { 'properties' => compound([{ 'type' => 'ordred', 'before' => 'a', 'after' => 'b' }]) }
      described_class.new(profile, warnings).validate!

      expect(warnings.join).to include('ordred').and include('dates')
    end

    it 'warns when a rule omits the fields it compares' do
      profile = { 'properties' => compound([{ 'type' => 'ordered' }]) }
      described_class.new(profile, warnings).validate!

      expect(warnings.join).to include('dates')
    end

    it 'ignores a compound that declares no validations' do
      profile = { 'properties' => { 'dates' => { 'type' => 'hash' } } }
      described_class.new(profile, warnings).validate!

      expect(warnings).to be_empty
    end

    it 'ignores a malformed validations value rather than raising' do
      profile = { 'properties' => compound('not a list') }

      expect { described_class.new(profile, warnings).validate! }.not_to raise_error
    end

    it 'ignores a profile with no properties' do
      expect { described_class.new({}, warnings).validate! }.not_to raise_error
    end
  end
end
