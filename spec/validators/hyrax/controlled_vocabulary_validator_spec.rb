# frozen_string_literal: true

RSpec.describe Hyrax::ControlledVocabularyValidator do
  subject(:validator) { described_class.new }

  let(:resource)   { build(:hyrax_work) }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }

  let(:license_terms) do
    [
      HashWithIndifferentAccess.new(id: 'http://creativecommons.org/licenses/by/4.0/', term: 'Attribution 4.0', active: true),
      HashWithIndifferentAccess.new(id: 'http://creativecommons.org/licenses/by-sa/4.0/', term: 'Attribution-ShareAlike 4.0', active: true),
      HashWithIndifferentAccess.new(id: 'http://creativecommons.org/licenses/by/3.0/us/', term: 'Attribution 3.0 United States', active: false)
    ]
  end

  let(:resource_type_terms) do
    [
      HashWithIndifferentAccess.new(id: 'Article', term: 'Article'),
      HashWithIndifferentAccess.new(id: 'Book', term: 'Book')
    ]
  end

  let(:license_authority)       { FakeAuthority.new(license_terms) }
  let(:resource_type_authority) { FakeAuthority.new(resource_type_terms) }

  before do
    allow(Qa::Authorities::Local).to receive(:subauthorities).and_return(['licenses', 'resource_types'])
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with('licenses').and_return(license_authority)
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with('resource_types').and_return(resource_type_authority)
  end

  describe '#validate' do
    context 'when the change set has no controlled vocabulary fields' do
      it 'adds no errors' do
        validator.validate(change_set)

        expect(change_set.errors).to be_empty
      end
    end

    context 'when fields have valid terms' do
      before do
        allow(change_set).to receive(:fields).and_return(
          'license' => [],
          'resource_type' => []
        )
        allow(change_set).to receive(:license).and_return(['http://creativecommons.org/licenses/by/4.0/'])
        allow(change_set).to receive(:resource_type).and_return(['Article'])
      end

      it 'adds no errors' do
        validator.validate(change_set)

        expect(change_set.errors).to be_empty
      end
    end

    context 'when fields have blank values' do
      before do
        allow(change_set).to receive(:fields).and_return('license' => [])
        allow(change_set).to receive(:license).and_return(['', nil])
      end

      it 'adds no errors' do
        validator.validate(change_set)

        expect(change_set.errors).to be_empty
      end
    end

    context 'when an authority has no terms' do
      let(:license_authority) { FakeAuthority.new([]) }

      before do
        allow(change_set).to receive(:fields).and_return('license' => [])
        allow(change_set).to receive(:license).and_return(['anything'])
      end

      it 'adds no errors' do
        validator.validate(change_set)

        expect(change_set.errors).to be_empty
      end
    end

    context 'when a field has an invalid term' do
      before do
        allow(change_set).to receive(:fields).and_return('license' => [])
        allow(change_set).to receive(:license).and_return(['http://bogus.example.com/fake'])
      end

      it 'adds errors to the change set' do
        validator.validate(change_set)

        expect(change_set.errors[:license]).to be_present
        expect(change_set.errors.full_messages).to include(match(/license.*unrecognized.*bogus/i))
      end
    end

    context 'when multiple fields have invalid terms' do
      before do
        allow(change_set).to receive(:fields).and_return(
          'license' => [],
          'resource_type' => []
        )
        allow(change_set).to receive(:license).and_return(['bad-license'])
        allow(change_set).to receive(:resource_type).and_return(['NotARealType'])
      end

      it 'adds errors for all invalid fields' do
        validator.validate(change_set)

        expect(change_set.errors[:license]).to be_present
        expect(change_set.errors[:resource_type]).to be_present
      end
    end

    context 'when a field has an inactive term' do
      before do
        allow(change_set).to receive(:fields).and_return('license' => [])
        allow(change_set).to receive(:license).and_return(['http://creativecommons.org/licenses/by/3.0/us/'])
      end

      it 'adds errors for the inactive term' do
        validator.validate(change_set)

        expect(change_set.errors.full_messages).to include(match(/license.*unrecognized.*by\/3.0\/us/i))
      end
    end

    context 'when a term has no active field' do
      before do
        allow(change_set).to receive(:fields).and_return('resource_type' => [])
        allow(change_set).to receive(:resource_type).and_return(['Article'])
      end

      it 'treats it as active and adds no errors' do
        validator.validate(change_set)

        expect(change_set.errors).to be_empty
      end
    end

    context 'when a field has a mix of valid and invalid terms' do
      before do
        allow(change_set).to receive(:fields).and_return('license' => [])
        allow(change_set).to receive(:license).and_return(
          ['http://creativecommons.org/licenses/by/4.0/',
           'http://bogus.example.com/fake']
        )
      end

      it 'adds errors only for invalid terms' do
        validator.validate(change_set)

        expect(change_set.errors.full_messages).to include(match(/license.*unrecognized.*bogus/i))
        expect(change_set.errors.full_messages).not_to include(match(/by\/4.0/i))
      end
    end
  end

  describe 'ChangeSet integration' do
    it 'is registered on Hyrax::ChangeSet and inherited by subclasses' do
      form = Hyrax::Forms::ResourceForm.new(resource: resource)
      allow(form).to receive(:fields).and_return('license' => [])
      allow(form).to receive(:license).and_return(['http://bogus.example.com/fake'])

      expect(form.valid?).to be false
      expect(form.errors[:license]).to be_present
    end
  end
end
