require 'spec_helper'

RSpec.describe Hyrax::QaSelectService, no_clean: true do
  let(:authority) do
    # Implementing an ActiveRecord interface as required for this spec
    # rubocop:disable RSpec/InstanceVariable
    Class.new do
      def initialize(map)
        @map = map
      end

      def all
        @map
      end

      def find(id)
        @map.detect { |item| item[:id] == id }
      end
    end
    # rubocop:enable RSpec/InstanceVariable
  end
  let(:authority_map) do
    [
      HashWithIndifferentAccess.new(term: 'Active Label', label: 'Active Label', id: 'active-id', active: true),
      HashWithIndifferentAccess.new(term: 'Inactive Label', label: 'Inactive Label', id: 'inactive-id', active: false),
      HashWithIndifferentAccess.new(label: 'Active No Term', id: 'active-no-term-id', active: true)
    ]
  end
  before do
    allow(Qa::Authorities::Local).to receive(:subauthority_for).with(authority_name).and_return(authority.new(authority_map))
  end
  let(:authority_name) { 'respect_my' }
  let(:qa_select_service) { described_class.new(authority_name) }

  describe '#select_all_options' do
    subject { qa_select_service.select_all_options }
    it 'will be Array of Arrays<label, id>' do
      expect(subject).to eq([['Active Label', 'active-id'], ['Inactive Label', 'inactive-id'], ['Active No Term', 'active-no-term-id']])
    end
  end

  describe '#select_active_options' do
    subject { qa_select_service.select_active_options }
    it 'will be Array of Arrays<label, id>' do
      expect(subject).to eq([['Active Label', 'active-id'], ['Active No Term', 'active-no-term-id']])
    end
  end

  describe '#label' do
    context 'for item with a "term" propery' do
      subject { qa_select_service.label('active-id') }
      it { is_expected.to be_a(String) }
    end
    context 'for item without a "term" property' do
      it 'will raise KeyError' do
        expect { qa_select_service.label('active-no-term-id') }.to raise_error(KeyError)
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
