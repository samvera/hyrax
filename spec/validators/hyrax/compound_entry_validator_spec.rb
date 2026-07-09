# frozen_string_literal: true

RSpec.describe Hyrax::CompoundEntryValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :relationships
      validates_with Hyrax::CompoundEntryValidator
    end
  end
  let(:record) { record_class.new.tap { |r| r.relationships = entries } }
  let(:entries) { [] }

  # A schema with one required-sub-property compound (`relationships`), optional
  # at the compound level.
  let(:definition) do
    { required: false,
      subproperties: { 'related_item' => { type: 'work_or_url', required: true },
                       'relationship_type' => { type: 'controlled', required: true } } }
  end
  let(:schema) { instance_double(Hyrax::CompoundSchema, definitions: { relationships: definition }) }

  before do
    allow(Hyrax::CompoundSchema).to receive(:for).and_return(schema)
  end

  # Compound errors are attached to :base (so the work and collection forms,
  # which render errors differently, both show them cleanly), and the message
  # names the compound.
  context 'with no rows (optional compound)' do
    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a complete row' do
    let(:entries) { [{ 'related_item' => 'work-1', 'relationship_type' => 'References' }] }

    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row missing a required sub-property' do
    let(:entries) { [{ 'related_item' => 'work-1' }] }

    it 'adds one base error' do
      record.valid?
      expect(record.errors[:base].size).to eq(1)
    end

    it 'names the compound and the missing sub-property in the message' do
      # Assert the English wording under :en, so the test is independent of the
      # suite's default locale (other locales need only the same key structure).
      I18n.with_locale(:en) do
        record.valid?
        expect(record.errors[:base].first).to include('Relationships').and include('Relationship type')
      end
    end
  end

  context 'when the compound itself is required' do
    let(:definition) { super().merge(required: true) }

    context 'and empty' do
      it 'flags the empty compound by name' do
        # English wording; see the note above on locale.
        I18n.with_locale(:en) do
          record.valid?
          expect(record.errors[:base].first).to include('Relationships').and include('at least one entry')
        end
      end
    end

    context 'and populated completely' do
      let(:entries) { [{ 'related_item' => 'work-1', 'relationship_type' => 'References' }] }

      it 'is valid' do
        record.valid?
        expect(record.errors[:base]).to be_empty
      end
    end
  end

  context 'when the record does not respond to the compound reader' do
    let(:record) do
      Class.new do
        include ActiveModel::Validations
        validates_with Hyrax::CompoundEntryValidator
      end.new
    end

    it 'skips it without error' do
      expect { record.valid? }.not_to raise_error
    end
  end
end
