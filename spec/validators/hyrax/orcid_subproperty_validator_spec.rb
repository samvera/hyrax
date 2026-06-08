# frozen_string_literal: true

RSpec.describe Hyrax::OrcidSubpropertyValidator do
  let(:record_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :participants
      validates_with Hyrax::OrcidSubpropertyValidator
    end
  end
  let(:record) { record_class.new.tap { |r| r.participants = entries } }
  let(:entries) { [] }

  # A schema with one orcid sub-property on the `participants` compound. The
  # validator selects orcid sub-properties off the schema, so the spec stubs
  # CompoundSchema.for to return a definition with one.
  let(:definition) do
    { required: false,
      subproperties: {
        'participant_name' => { type: 'string' },
        'participant_orcid' => { type: 'orcid', badge_for: 'participant_name' }
      } }
  end
  let(:schema) { instance_double(Hyrax::CompoundSchema, definitions: { participants: definition }) }

  before do
    allow(Hyrax::CompoundSchema).to receive(:for).and_return(schema)
  end

  context 'with no rows' do
    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row that omits the orcid' do
    let(:entries) { [{ 'participant_name' => 'Hosseini, Mohammad' }] }

    it 'is valid (orcid is optional)' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row that has a blank orcid' do
    let(:entries) { [{ 'participant_name' => 'Hosseini, Mohammad', 'participant_orcid' => '' }] }

    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row whose orcid is in the bare-iD form' do
    let(:entries) { [{ 'participant_name' => 'X', 'participant_orcid' => '0000-0002-2385-985X' }] }

    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row whose orcid is in the full URL form' do
    let(:entries) { [{ 'participant_name' => 'X', 'participant_orcid' => 'https://orcid.org/0000-0002-2385-985X' }] }

    it 'is valid' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end

  context 'with a row whose orcid is malformed' do
    let(:entries) { [{ 'participant_name' => 'X', 'participant_orcid' => 'not-an-id' }] }

    it 'adds one base error naming the compound and the sub-property' do
      I18n.with_locale(:en) do
        record.valid?
        expect(record.errors[:base].size).to eq(1)
        expect(record.errors[:base].first).to include('Participants').and include('Participant orcid')
      end
    end
  end

  context 'with multiple rows where only one orcid is malformed' do
    let(:entries) do
      [{ 'participant_name' => 'Ok', 'participant_orcid' => '0000-0001-2345-6789' },
       { 'participant_name' => 'Bad', 'participant_orcid' => 'still-not-valid' }]
    end

    it 'adds an error only for the malformed row' do
      record.valid?
      expect(record.errors[:base].size).to eq(1)
    end
  end

  context 'when a compound has no orcid sub-properties' do
    let(:definition) do
      { required: false,
        subproperties: { 'plain' => { type: 'string' } } }
    end
    let(:entries) { [{ 'plain' => 'whatever' }] }

    it 'does not touch the row' do
      record.valid?
      expect(record.errors[:base]).to be_empty
    end
  end
end
