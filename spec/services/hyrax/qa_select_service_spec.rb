# frozen_string_literal: true
RSpec.describe Hyrax::QaSelectService do
  let(:authority_map) do
    [
      HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
      HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
      HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true),
      HashWithIndifferentAccess.new(term: 'No Active Flag Term', label: 'No Active Flag Label', id: 'no-active-flag-id')
    ]
  end

  let(:authority) { FakeAuthority }
  let(:authority_name) { 'respect_my' }
  let(:service_authority) { authority.new(authority_map) }
  let(:qa_select_service) { described_class.new(authority_name) }
  let(:service) { qa_select_service }

  before do
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with(authority_name).and_return(service_authority)
  end

  include_examples "a tolerant authority service"

  describe '#select_all_options' do
    subject { qa_select_service.select_all_options }

    it 'will be Array of Arrays<label, id>' do
      expect(subject).to eq([['Active Label', 'active-id'], ['Inactive Label', 'inactive-id'], ['Active No Term', 'active-no-term-id'], ['No Active Flag Label', 'no-active-flag-id']])
    end
  end

  describe '#select_active_options' do
    subject { qa_select_service.select_active_options }

    context 'with only active/inactive flagged terms' do
      let(:authority_map) do
        [
          HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
          HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
          HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true)
        ]
      end

      it 'will be Array of Arrays<label, id>' do
        expect(subject).to eq([['Active Label', 'active-id'], ['Active No Term', 'active-no-term-id']])
      end
    end

    context 'when a key has no active property' do
      it 'raises KeyError' do
        expect { subject }.to raise_error(KeyError)
      end
    end
  end

  describe '#active?' do
    context 'for item with an "active" property' do
      subject { qa_select_service.active?('active-id') }

      it { is_expected.to be_truthy }
    end
    context 'for item without an "active" property' do
      let(:authority_map) do
        [
          HashWithIndifferentAccess.new(term: 'term', label: 'label', id: 'with-term-no-active-state-id')
        ]
      end

      it 'will raise KeyError' do
        expect { qa_select_service.active?('with-term-no-active-state-id') }.to raise_error(KeyError)
      end
    end
  end
end
